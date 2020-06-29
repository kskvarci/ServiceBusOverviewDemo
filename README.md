# Agenda
- Messaging on Azure (options)
- Service Bus Overview
- Demo
	- Namespace
	- Writing and Reading from Queues and Topics
	- Monitoring
	- Geo Redundancy / Alias Configuration
	- Failover

# Messaging on Azure
- **Event Grid:**  
Event Grid uses a pub-sub model. It's designed for event based programming and deals in lightweight notifications of condition or state changes.   

- **Event Hub:**  
Event Hub is used for data 	streaming.  

- **Service Bus:**  
Service bus is used for is designed for traditional enterprise messaging. This is the service to use if your application needs a way of passing high value messages that cannot be lost or duplicated.

# Service Bus Overview
- Everything starts w/ creation of a Service Bus **Namespace**. A namespace is a resource that gets deployed to a resource group in Azure with the following characteristics:
	- **Name:**  
This is globally unique. A DNS name (*.servicebus.windows.net)  

	- **Location:**  
Region  

	- **Pricing Tier:**  
Either Basic Standard or Premium.  

## Pricing Tiers
- **Basic:**
	- No message sessions

- **Standard:**
	- Shared CPU / Memory across customers.  

- **Premium:**
	- CPU and memory isolation which equates to predictable and consistent performance (scale unit).
	- Scale from 1-8 "messaging units" (MU).
	- An MU is essentially a dedicate VM.
	- The number of MUs you scale to should be based on observed load (CPU).
	- Scaling can be automated using Azure Automation. No autoscale built into the service itself.
	- Recommended for all production use cases.
	- **Required** for virtual network integration features like services endpoints and private link.  
	- Pricing for premium is linear based on the number of MUs in operation per hour.

## Two main capabilities
- Service Bus Queues:
![](images/about-service-bus-queue.png "")
- Service Bus Topics:
![](images/about-service-bus-topic.png "")
## Advanced Capabilities (Across both Topics and Queues)
- **[Message Sessions](https://docs.microsoft.com/en-us/azure/service-bus-messaging/message-sessions)**
	- Concurrent de-multiplexing of interleaved message streams.
	- [Java SDK example](https://github.com/Azure/azure-sdk-for-java/blob/master/sdk/servicebus/azure-messaging-servicebus/src/samples/java/com/azure/messaging/servicebus/SendAndReceiveSessionMessageSample.java)
	- Needs to be enabled at the queue level.
	- Once enabled, Session ID (app designated) must be specified when submitting messages to a topic or queue.
	- Generally used in "first in, first out" and "request-response" patterns.
	![](images/sessions.png "")
  
- [**Autoforwarding**](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-auto-forwarding)
	- Automatically remove messages placed in one queue or subscription and put them in a second queue (or topic).
	- Enabled via code on a per-queue or subscription basis.
	- Target needs to be in the same namespace.
	- Use to scale out topics as subscriptions on a given topic are limited to 2000:
	![](images/autoforwardscale.gif "")
	- Use to decouple senders and receivers
	- In below example a subscription is set up to forwarl all message in a topic into a queue.
	![](images/autoforwarddecouple.gif "")
  
- [**Dead-letter queue**](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues)
	- Secondary sub-queue for queues and topic subscriptions.
	- auto created and cannot be removed.
	- Designed to hold messages that cannot be delivered or processed.
	- Not automatically cleaned up.
	- The messaging engine [may place messages in this queue](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues#moving-messages-to-the-dlq). Your app may explicitly do so as well.

- [**Scheduled delivery**](https://docs.microsoft.com/en-us/azure/service-bus-messaging/message-sequencing#scheduled-messages)
	- Submit messages to a topic or queue for delayed processing.
	- Messages will not show in until the scheduled time.
	- Schedule messages either by setting a property on the message or explicitly calling the scheduleMessageAsync API.
  
- [**Message deferral**](https://docs.microsoft.com/en-us/azure/service-bus-messaging/message-deferral)
	- Allows a client to defer processing of a message that it is willing to process.
	- Message stays safely in the messaging store but cannot be read unless explicitley retrieved by sequence number.  

- [**Batching** ](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-performance-improvements?tabs=net-standard-sdk#client-side-batching)
	- Delay sending of a message to a queue or topic until a threshold is hit (time based). After which all messages in the windows are sent as a single batch.
	- Can be used to improve overall throughput by reducing transactions.
	- Client side batching is a function of the SDK being used to send messages.
	- We also batch our writes to the underlying messaging store. This happens transparently.  

- [**Transactions**](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-transactions)
	- Service Bus is at its core a transactional message broker. E.G. if it accepts a message it has already been stored and labeled w/ a sequence number.
	- It's also possible to group your operations within the scope of a transaction so that all operations must succeed for the transaction to be committed to the entity.

- [**Filtering and Actions**](https://docs.microsoft.com/en-us/azure/service-bus-messaging/topic-filters)
	- Applies only to topic subscriptions.
	- Filter which messages you want to receive.
	- Filters are specified via topic subscription rules. Rules can contain conditions as follows:
		- Boolean
		- SQL
		- Correlation
	- Filters evaluate message properties not the message body.
	- Can negatively impact throughput (specifically SQL based filters).

- [**Auto-delete on idle**](https://docs.microsoft.com/en-us/dotnet/api/microsoft.servicebus.messaging.queuedescription.autodeleteonidle?view=azure-dotnet)
	- Delete a queue if the queue is idle for a set duration. Minimum duration is 5 minutes.  

- [**Duplicate detection**](https://docs.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection)
	- If a client sends the same message multiple times Service Bus will discard the duplicates.
	- Enabled on a queue or topic. Off by default.
	- Must be enabled at queue creation time.
	- Duplicate detection is based off of MessageID which is set by the application.
	- Can negatively impact throughput  

## High Availability / Disaster Recovery
The [documented SLA](https://azure.microsoft.com/en-us/support/legal/sla/service-bus/v1_1/) for Service Bus irrespective of configuration is 99.9%.
### HA
- [Availability zones](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-outages-disasters#availability-zones) are supported only with Service Bus Premium SKU and must be enabled at creation time. This spreads the namespace across three distinct zones in regions that support it. Both East US 2 and Central US support zones.
- Three copies of messaging store (1 primary and 2 secondary) are maintained. Service Bus keeps all the three copies in sync for data and management operations. If the primary copy fails, one of the secondary copies is promoted to primary with no perceived downtime.  

### DR - Geo-Replication
- Service Bus Premium SKU supports [Geo-Disaster Recovery](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-geo-dr).
- Two namespaces in different regions can be paired together in a primary / secondary relationship.
- When paired, all entity **metadata** is replicated between primary and secondary namespaces.
- The message store data itself is **NOT** replicated. This includes not only messages but also sessions, duplicate detection and schedule messages.
- The primary / secondary namespaces are fronted by an alias that can be used by connecting clients. This alias will point at the current primary namespace.
- Failover is manual (unless the customer automates). When failover is initiated, the alias is re-pointed to the secondary namespace and the geo-replication relationship is broken. 
- Post failover, a new geo-replication relationship must be formed if desired.


# Demo
- [ARM Template](ARM/azuredeploy-namespace.json) Overview (Namespace)
- Deployed Resource Walk-through
	- SKU
	- Zone Redundancy
	- Messaging Units (scaling)
