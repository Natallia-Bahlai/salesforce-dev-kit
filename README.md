# salesforce-dev-kit


<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Query Builder

Query Builder provides a convenient, fluent interface for creating and running salesforce SOQL queries.

Usage must follow this sequence:

1. new Query(SObjectType fromObject, String[] fields)
2. .apply(filter)
3. .apply(orderBy)
4. .apply(pagination)
5. .apply(nullsOrder)
6. .query() or dataQuery or countQuery

---

### Examples

With single condition
```apex
String[] fields = new String[]{
        'Id'
        , 'Name'
        , '' + Contact.FirstName
        , '' + Contact.LastName
        , '' + Contact.Birthdate
};
Query.Condition condition = new Query.Condition('' + Contact.LastViewedDate, 'LAST_YEAR');
Query.Filter filter = new Query.Filter(condition);

String soql = new Query(Contact.SObjectType, fields)
        .apply(filter)
        .apply(new Query.OrderBy(Query.Order.RECENT))
        .apply(Query.NullsOrder.NULLS_FIRST)
        .dataQuery;

List<SObject> results = Database.query(soql);
system.debug(LoggingLevel.INFO, 'Result SOQL: ' + soql);
```
Result SOQL:
```sql
SELECT Id, Name, FirstName, LastName, Birthdate FROM Contact WHERE LastViewedDate = LAST_YEAR ORDER BY CreatedDate DESC NULLS FIRST
```
---
With multiple conditions and pagination:

```apex
String[] fields = new String[]{
        'Id'
        , '' + Lead.FirstName
        , '' + Lead.LastName
        , '' + Lead.LeadSource
};
Query.Condition[] conditions = new Query.Condition[]{
        new Query.Condition('' + Lead.Status, 'Open')
        , new Query.Condition('' + Lead.LeadSource, new String[] {'Web', 'Email', 'etc'})
};
Query.Filter filter = new Query.Filter(conditions);

Query.PageContext pageCtx = new Query(Contact.SObjectType, fields)
        .apply(filter)
        .apply(new Query.OrderBy(Query.Order.A_Z))
        .apply(new Query.Pager(10, 1))
        .query();

system.debug(LoggingLevel.INFO, 'Page Data: ' + pageCtx.pageData);
system.debug(LoggingLevel.INFO, 'Total Pages: ' + pageCtx.totalPages);

```
Result SOQL:
```sql
SELECT Id, FirstName, LastName, LeadSource FROM Contact WHERE Status = 'Open' AND LeadSource IN ('Web', 'Email', 'etc') ORDER BY Name ASC LIMIT 10 OFFSET 0
SELECT count() FROM Contact WHERE Status = 'Open' AND LeadSource IN ('Web', 'Email', 'etc')
```

---
