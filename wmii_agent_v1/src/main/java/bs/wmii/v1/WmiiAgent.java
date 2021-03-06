package bs.wmii.v1;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.Reader;
import java.util.HashSet;
import java.util.Set;

import jade.content.Concept;
import jade.content.lang.Codec;
import jade.content.onto.OntologyException;
import jade.core.Agent;
import jade.lang.acl.ACLMessage;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import bs.jade.MessageReceiverFacade;
import bs.wmii.v1.ontology.ClientEvent;
import bs.wmii.v1.ontology.TagEvent;
import bs.wmii.v1.ontology.WmiiOntology;

public class WmiiAgent extends jade.core.Agent {
	private Logger log;

	private SubscriptionManager submgr;
	private ClientInfoHandler clientInfoHandler;

	private Codec codec = new jade.content.lang.sl.SLCodec();

	private Process wmiiProcess;

	private static Set<String> ignoredEventNames = new HashSet<>();
	static {
		ignoredEventNames.add("AreaFocus");
		ignoredEventNames.add("ColumnFocus");
		ignoredEventNames.add("Key");
	}

	public WmiiAgent() {
		submgr = new SubscriptionManager(this);
		clientInfoHandler = new ClientInfoHandler();
	}

	private void startEventRelayThread() {
		Runnable r = new Runnable() {
				public void run() {
					try {
						wmiiProcess = new ProcessBuilder("wmiir", "read", "/event").redirectErrorStream(true).start();
					} catch(IOException ex) {
						log.error("Failed to start wmiir process for event relay thread", ex);
						return;
					}
					BufferedReader rdr = new BufferedReader(new InputStreamReader(wmiiProcess.getInputStream()));
					readAndRelayWmiiEvents(rdr);
				}
			};
		Thread t = new Thread(r, "wmii-event-relay");
		t.setDaemon(true);
		t.start();
	}

	protected void setup() {
		log = LoggerFactory.getLogger(getName());

		getContentManager().registerLanguage(codec);
		getContentManager().registerOntology(WmiiOntology.getInstance());
		addBehaviour(submgr);
		// addBehaviour(new MessageReceiverFacade(this, clientInfoHandler,
		// 									   clientInfoHandler.getMessageTemplate()));

		startEventRelayThread();
	}

	private Concept parseEvent(String l) {
		String parts[] = l.split(" ");
		String eventName = parts[0];
		if ("ClientFocus".equals(eventName)) {
			String clientId = parts[1];
			if ("<nil>".equals(clientId))
				return null;
			else
				return new ClientEvent(ClientEvent.EVENT_TYPE_FOCUS, clientId);
		} else if ("CreateClient".equals(eventName)) {
			String clientId = parts[1];
			return new ClientEvent(ClientEvent.EVENT_TYPE_CREATED, clientId);
		} else if ("DestroyClient".equals(eventName)) {
			String clientId = parts[1];
			return new ClientEvent(ClientEvent.EVENT_TYPE_DESTROYED, clientId);
		} else if ("FocusTag".equals(eventName)) {
			String tagId = parts[1];
			return new TagEvent(TagEvent.EVENT_TYPE_FOCUS, tagId);
		} else if ("CreateTag".equals(eventName)) {
			String tagId = parts[1];
			return new TagEvent(TagEvent.EVENT_TYPE_CREATED, tagId);
		} else if ("DestroyTag".equals(eventName)) {
			String tagId = parts[1];
			return new TagEvent(TagEvent.EVENT_TYPE_DESTROYED, tagId);
		} else {
			if (!ignoredEventNames.contains(eventName))
				log.warn("unrecognized event string '" + l + "'");
			return null;
		}
	}

	private void broadcastEvent(Concept event) throws Codec.CodecException, OntologyException {
		ACLMessage m = new ACLMessage(ACLMessage.INFORM);
		m.setLanguage(codec.getName());
		m.setOntology(WmiiOntology.ONTOLOGY_NAME);
		getContentManager().fillContent(m, new jade.content.onto.basic.Done(event));
		submgr.addReceivers(m);
		send(m);
	}

	private void readAndRelayWmiiEvents(BufferedReader r) {
		String l = "";
		while (true) {
			try {
				l = r.readLine();
				Concept event = parseEvent(l);
				if (event == null)
					continue;
				broadcastEvent(event);
			} catch(Exception ex) {
				log.error("Error during wmii event relay", ex);
				try {
					// we leave a short delay here to prevent long error outputs
					// when stream stops blocking on the read
					Thread.sleep(10 * 1000);
				} catch(Exception interrupted) { }
			}
		}
	}
}
