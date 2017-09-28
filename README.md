# salesforce-dev-kit


<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

```apex
String fields = new String[]{
        'Id'
        , 'Name'
        , '' + Contact.FirstName
        , '' + Contact.LastName
        , '' + Contact.Birthdate
};
Query.Condition[] conditions = new Query.Condition[]{
        new Query.Condition('' + Contact.CreatedDate, 'LAST_YEAR')
};
Query.Filter filter = new Query.Filter(conditions);

Query.PageContext pageCtx = new Query(Contact.SObjectType, fields)
        .apply(filter)
        .apply(new Query.OrderBy(Query.Order.A_Z))
        .apply(new Query.Pager(10, 1))
        .query();
```


