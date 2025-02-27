
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopCustomers AS (
    SELECT 
        c.c_name,
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, c.c_nationkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 10
),
HighValueItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    tc.c_name,
    n.n_name AS nation_name,
    SUM(CASE WHEN ro.order_rank <= 5 THEN ro.o_totalprice ELSE 0 END) AS top_order_value,
    COUNT(DISTINCT hvi.p_partkey) AS high_value_items_count,
    SUM(hvi.total_revenue) AS total_revenue_from_items
FROM 
    RankedOrders ro
JOIN 
    TopCustomers tc ON ro.o_orderkey = tc.total_orders
JOIN 
    nation n ON tc.c_nationkey = n.n_nationkey
JOIN 
    HighValueItems hvi ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_nationkey)
GROUP BY 
    tc.c_name, n.n_name
ORDER BY 
    total_revenue_from_items DESC, top_order_value DESC
LIMIT 10;
