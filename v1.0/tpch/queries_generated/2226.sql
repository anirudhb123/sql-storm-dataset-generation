WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - COALESCE(l.l_discount, 0))) AS total_revenue,
    AVG(CASE WHEN cs.order_count > 0 THEN cs.order_count ELSE NULL END) AS avg_orders_per_customer,
    MAX(ps.total_available) AS max_avail_qty,
    MIN(ps.avg_supply_cost) AS min_supply_cost
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerOrderCount cs ON s.s_nationkey = cs.c_custkey
WHERE 
    n.n_name LIKE 'A%' 
    AND l.l_shipdate >= '2022-01-01'
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
