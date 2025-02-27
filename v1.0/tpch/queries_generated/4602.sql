WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) as order_rank,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(ranks.order_total) AS avg_order_value,
    COALESCE(s.total_available, 0) AS total_available,
    MAX(s.distinct_parts) AS max_distinct_parts,
    RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS revenue_rank
FROM 
    RankedOrders ranks
JOIN 
    nation n ON ranks.c_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierStats s ON ranks.o_orderkey = s.s_suppkey
JOIN 
    lineitem l ON ranks.o_orderkey = l.l_orderkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;
