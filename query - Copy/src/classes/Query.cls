/***
 * @description     Query records by filter, order or with pagination capability
 * @author          natallia.bahlai@accenture.com
 * @date            5/07/2017
 * @company         Accenture
 */
public virtual class Query {

    public class InvalidQueryException extends Exception {}
    
    /*              INNER CLASSES               */
    public class Filter {
        public Condition[] condtions;
        public Order orderBy;

        public Filter() {
            this.condtions = new Condition[]{};
        }
        public Filter(Condition condtion) {
            this.condtions = new Condition[]{condtion};
        }
        public Filter(Condition[] condtions) {
            this.condtions = condtions;
        }
    }

    public class Searcher {
        public Condition[] condtions;
    }

    public class Pager {
        public Integer pageSize;
        public Integer pageNumber;

        public Pager(Integer pageSize, Integer pageNumber) {
            if (pageNumber < 1) throw new InvalidQueryException('Page # should be greater than 0');
            this.pageSize = pageSize;
            this.pageNumber = pageNumber;
        }
    }

    //TODO @Nat consider deprecaion of field/value?
    public virtual class Condition {
        public String field;
        public Object value;//TODO: object type
        private String statement;

        public Condition() {
        }

        public Condition(String statement) {
            this.statement = statement;
        }

        public Condition(String field, Object value) {
            
            this.field = field;
            this.value = value;

            if (this.value instanceof String[])
                this.statement = String.format(PTRN_IN, new String[]{
                        String.valueOf(this.field),
                        '(\'' + String.join((String[]) this.value, '\', \'') + '\')'
                });
            else if (this.value instanceof Boolean )
                this.statement = String.format(PTRN_EQUALS, new String[]{
                        String.valueOf(this.field),
                        String.valueOf((Boolean) this.value)
                });
            else if (this.value instanceof Integer)
                this.statement = String.format(PTRN_EQUALS, new String[]{
                        String.valueOf(this.field),
                        String.valueOf((Integer) this.value)
                });
            else if (this.value instanceof String && ((String) this.value).startsWith('(SELECT'))//TODO: check regex
                this.statement = String.format(PTRN_IN, new String[]{
                        String.valueOf(this.field),
                        String.valueOf(this.value)
                });
            else if (this.value instanceof String || this.value instanceof Id) 
                this.statement = String.format(PTRN_EQUALS, new String[]{
                        String.valueOf(this.field),
                        '\'' + String.valueOf(this.value) + '\''
                });
        }
    }

    public class WithIds extends Condition {
        public WithIds(String idFld, Set<Id> ids) {
            //if (ids == null || ids.isEmpty()) throw Ex
            this.field = idFld;
            this.value = ids;
            this.statement = idFld + ' IN :ids';
        }

        public WithIds(Set<Id> ids) {
            this('Id', ids);
        }
    }

    public class Exclusion extends Condition {
        public Exclusion(String field, Object value) {
            this.field = field;
            this.value = value;

            if (this.value instanceof String[]) {
                this.statement = String.format(PTRN_NOT_IN, new String[]{
                        String.valueOf(this.field),
                        '(\'' + String.join((String[]) this.value, '\', \'') + '\')'
                });
            }
        }
        public Exclusion(String field, Set<String> value) {//TODO @Nat make consistent with Inclusion
            this.field = field;
            this.value = value;

            this.statement = String.format(PTRN_EXCLUDES, new String[]{
                    String.valueOf(this.field),
                    String.join(new List<String>( value ), '\', \'')
            });
        }
    }

    public class Inclusion extends Condition {
        public Inclusion(String field, String[] value) {
            this.field = field;
            this.value = value;

            if (this.value instanceof String[]) {
                this.statement = String.format(PTRN_INCLUDES, new String[]{
                        String.valueOf(this.field),
                        String.join((String[]) this.value, '\', \'')
                });
            }
        }
    }

    private abstract class LogicalJoin extends Condition {
        protected LogicalJoin(Condition[] conditions, String logicalJoin) {
            String[] fragments = new String[]{};
            for (Condition condition : conditions) {
                if (String.isNotEmpty(condition.statement)) fragments.add(condition.statement);
            }
            this.statement = '(' + String.join(fragments, logicalJoin) + ')';
        }

    }

    public class ORJoin extends LogicalJoin {
        public ORJoin(Condition condition1, Condition condition2) {
            this(new Condition[] { condition1, condition2});
        }
        public ORJoin(Condition[] conditions) {
            super(conditions, ' OR ');
        }
    }

    public class ANDJoin extends LogicalJoin {
        public ANDJoin(Condition condition1, Condition condition2) {
            this(new Condition[] { condition1, condition2});
        }
        public ANDJoin(Condition[] conditions) {
            super(conditions, ' AND ');
        }
    }


    public enum Order {
        POPULAR, RECENT, OLD, A_Z, Z_A
    }

    public enum NullsOrder { NULLS_LAST, NULLS_FIRST }

    public class OrderBy {
        public String field;
        public boolean isAsc;

        public OrderBy (String field) {
            this(field, true);
        }
        public OrderBy (String field, boolean isAsc) {
            this.field = field;
            this.isAsc = isAsc;
        }
        public OrderBy (Order orderBy) {

            if (Order.RECENT == orderBy) {
                this.field = 'CreatedDate';
                this.isAsc = false;
            }
            else if (Order.OLD == orderBy) {
                this.field = 'CreatedDate';
                this.isAsc = true;
            }
            else if (Order.A_Z == orderBy) {
                this.field = 'Name';
                this.isAsc = true;
            }
            else if (Order.Z_A == orderBy) {
                this.field = 'Name';
                this.isAsc = false;
            }
        }
    }

/*    public class GroupBy {
        public String field;

        public GroupBy (String field) {
            this.field = field;
        }
    }*/

    public virtual class PageContext {
        public List<SObject> pageData;
        public Integer totalSize = 0;
        public Integer pageSize;
        public Integer pageNumber;
        public Integer totalPages {
            get {
                return totalSize/pageSize + ((math.mod(totalSize, pageSize) > 0) ? 1 : 0);
            }
        }
        public Map<Id, SObject> extraData;  //Hold relevant details for pageData
    }

    private static String PTRN_QUERY = 'SELECT {0} FROM {1}';
    private static String PTRN_IN = '{0} IN {1}';
    private static String PTRN_NOT_IN = '{0} NOT IN {1}';
    private static String PTRN_EQUALS = '{0} = {1}';
    private static String PTRN_INCLUDES = '{0} INCLUDES (\'\'{1}\'\')';
    private static String PTRN_EXCLUDES = '{0} EXCLUDES (\'\'{1}\'\')';

    /*              INSTANCE VARIABLES              */
    public SObjectType type;
    public String[] fields;
    public Set<Id> ids;
    public String dataQuery;
    public String cntQuery;
    public PageContext pageCtx;

    public Query(SObjectType type, String[] fields) {
        this.type = type;
        this.fields = fields;
        this.dataQuery = String.format(PTRN_QUERY, new String[]{
                String.join(fields, ', ')
                , String.valueOf(type)
        });
        this.cntQuery = String.format(PTRN_QUERY, new String[]{
                'count()'
                , String.valueOf(type)
        });
        this.pageCtx = new PageContext();
        this.pageCtx.pageData = new List<SObject>();
    }

    /*              INSTANCE METHODS                */
    /***
     * @description     Apply given filtering
     * @author          natallia.bahlai@accenture.com
     * @date            6/07/2017
     */
    //todo: @Natallia process null
    public Query apply(Filter filter) {
        if (!filter.condtions.isEmpty()) {//TODO: check fields type to apply right clause
            String[] filterBy = new String[]{};
            for (Condition condition : filter.condtions) {
                if (condition instanceof WithIds) {
                    filterBy.add(condition.statement);
                    ids = (Set<Id>) condition.value;
                }
                else if (String.isNotEmpty(condition.statement)) filterBy.add(condition.statement);
            }

            if (filterBy.isEmpty()) return this;

            String whereFragment = ' WHERE ' + String.join(filterBy, ' AND ');
            this.dataQuery += whereFragment;
            this.cntQuery += whereFragment;
        }

        return this;
    }

    /***
     * @description     Apply Ordering
     * @author          natallia.bahlai@accenture.com
     * @date            5/07/2017
     */
    public virtual Query apply(Order orderBy) {
        return apply(new OrderBy(orderBy));
    }

    /***
     * @description     Apply Ordering by given field
     * @author          natallia.bahlai@accenture.com
     * @date            5/07/2017
     */
    public virtual Query apply(OrderBy orderBy) {
        this.dataQuery += ' ORDER BY ' + orderBy.field + ' ' + (orderBy.isAsc ? 'ASC' : 'DESC');

        return this;
    }



    /***
     * @description     Apply Ordering by given field
     * @author          natallia.bahlai@accenture.com
     * @date            5/07/2017
     */
    public virtual Query apply(OrderBy[] orderBys) {
        String[] fragments = new String[]{};
        for (OrderBy ob : orderBys) {
            fragments.add(ob.field + ' ' + (ob.isAsc ? 'ASC' : 'DESC'));
        }
        this.dataQuery += ' ORDER BY ' + String.join(fragments, ', ');

        return this;
    }

    /*
    public virtual QueryEntityService apply(GroupBy groupBy) {
        this.dataQuery += ' GROUP BY ' + groupBy.field;

        return this;
    }*/

    /***
     * @description     Apply pagination
     * @author          natallia.bahlai@accenture.com
     * @date            5/07/2017
     */
    public virtual Query apply(Pager pager) {
        if (pager.pageSize > 0) this.dataQuery += ' LIMIT ' + pager.pageSize;
        if (pager.pageNumber > 0) this.dataQuery += ' OFFSET ' + (pager.pageNumber - 1) * pager.pageSize;

        pageCtx.pageNumber = pager.pageNumber;
        pageCtx.pageSize = pager.pageSize;

        return this;
    }

    public virtual Query apply(NullsOrder order) {
        if (NullsOrder.NULLS_FIRST == order) this.dataQuery += ' NULLS FIRST';
        if (NullsOrder.NULLS_LAST == order) this.dataQuery += ' NULLS LAST';

        return this;
    }

    /***
     * @description     Query result records
     * @author          natallia.bahlai@accenture.com
     * @date            5/07/2017
     */
    public virtual PageContext query() {
        String cntQueryLog = cntQuery;
        if (ids != null) {
            cntQueryLog = cntQueryLog.replaceFirst(':ids', toListString(ids));
        }

        system.debug(LoggingLevel.DEBUG, dataQuery);
        system.debug(LoggingLevel.DEBUG, cntQueryLog);
        this.pageCtx.pageData = new SObject[pageCtx.totalSize];

        //TODO: @Natallia proper try/catch
        try {
            pageCtx.pageData.addAll(Database.query(dataQuery));
            pageCtx.totalSize += Database.countQuery(cntQuery);

            system.debug(LoggingLevel.DEBUG, pageCtx);
        }
        catch (Exception ex) {
            system.debug(LoggingLevel.ERROR, pageCtx);
            system.debug(LoggingLevel.ERROR, ex.getMessage());
        }
        return pageCtx;
    }

    public static String toListString(Set<Id> ids) {
        List<String> values = new List<String>();
        for (Id id :ids) values.add(id);
        return '(\'' + String.join(values, '\', \'') + '\')';
    }

    public static String toListString(String[] values) {
        return '(\'' + String.join(values, '\', \'') + '\')';
    }
}