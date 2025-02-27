WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_value > (SELECT AVG(ps_supplycost * ps_availqty) 
                       FROM partsupp ps)
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        l.l_linenumber, 
        l.l_extendedprice * (1 - l.l_discount) AS net_price,
        COALESCE(l.l_tax, 0) AS tax,
        l.l_returnflag
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
),
CustomerCount AS (
    SELECT 
        n.n_nationkey, 
        COUNT(DISTINCT c.c_custkey) AS num_customers
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(DISTINCT o.o_orderkey) AS region_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        region_orders > (SELECT AVG(region_orders) FROM 
                         (SELECT 
                              COUNT(DISTINCT o.o_orderkey) AS region_orders
                          FROM 
                              region r
                          JOIN 
                              nation n ON r.r_regionkey = n.n_regionkey
                          JOIN 
                              customer c ON n.n_nationkey = c.c_nationkey
                          JOIN 
                              orders o ON c.c_custkey = o.o_custkey
                          GROUP BY 
                              r.r_regionkey) AS temp)
)
SELECT 
    o.o_orderkey, 
    o.o_totalprice, 
    COUNT(DISTINCT li.l_linenumber) AS num_lineitems, 
    SUM(f.net_price) AS total_net_price,
    SUM(f.tax) AS total_tax,
    CASE WHEN COUNT(DISTINCT li.l_suppkey) = 0 THEN 'No Suppliers' 
         ELSE 'Has Suppliers' END AS supplier_status,
    COALESCE(tc.num_customers, 0) AS customer_count
FROM 
    RankedOrders o
LEFT JOIN 
    FilteredLineItems li ON o.o_orderkey = li.l_orderkey 
LEFT JOIN 
    HighValueSuppliers hs ON li.l_suppkey = hs.s_suppkey
LEFT JOIN 
    CustomerCount tc ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
WHERE 
    o.order_rank <= 10
GROUP BY 
    o.o_orderkey, o.o_totalprice, tc.num_customers
ORDER BY 
    o.o_orderdate DESC, num_lineitems DESC 
HAVING 
    (total_net_price > 500 AND total_tax < 100) OR 
    (supplier_status = 'No Suppliers' AND customer_count < 5);
