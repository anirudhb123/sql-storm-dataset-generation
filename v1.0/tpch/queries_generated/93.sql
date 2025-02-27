WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_orderkey) AS item_count,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_totalprice
)
SELECT 
    c.c_name AS customer_name,
    n.n_name AS nation_name,
    SUM(co.revenue) AS total_revenue,
    AVG(cs.s_acctbal) AS avg_supplier_acctbal,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    MAX(co.item_count) AS max_items_in_order
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.o_custkey
LEFT JOIN 
    RankedSuppliers cs ON cs.ps_partkey IN (SELECT ps_partkey FROM partsupp)
WHERE 
    co.order_rank <= 3 
    AND c.c_acctbal IS NOT NULL 
GROUP BY 
    c.c_name, n.n_name
HAVING 
    SUM(co.revenue) > 10000
ORDER BY 
    total_revenue DESC, c.c_name
LIMIT 50;
