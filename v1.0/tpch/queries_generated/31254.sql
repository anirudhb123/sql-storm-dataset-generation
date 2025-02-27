WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name AS customer_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
BestSuppliers AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
LatestOrders AS (
    SELECT 
        oh.o_orderkey,
        oh.customer_name,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        OrderHierarchy oh
    LEFT JOIN 
        lineitem l ON oh.o_orderkey = l.l_orderkey
    WHERE 
        oh.order_rank <= 5
    GROUP BY 
        oh.o_orderkey, oh.customer_name
)
SELECT
    n.n_name AS nation_name,
    COUNT(DISTINCT lo.customer_name) AS number_of_unique_customers,
    AVG(lo.total_value) AS average_order_value,
    COALESCE(SUM(bs.total_supply_cost), 0) AS total_below_average_supply_cost
FROM 
    LatestOrders lo
JOIN 
    customer c ON lo.customer_name = c.c_name
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    BestSuppliers bs ON bs.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = lo.o_orderkey) 
GROUP BY 
    n.n_name
ORDER BY 
    nation_name;
