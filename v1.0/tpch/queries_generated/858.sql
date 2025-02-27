WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_shippriority, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND 
        o.o_orderdate < '2023-12-31'
), 
SupplyCost AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
FullLineitem AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount, 
        l.l_tax, 
        COALESCE(p.p_name, 'Unknown') AS part_name, 
        r.r_name AS region_name
    FROM 
        lineitem l
    LEFT JOIN 
        part p ON l.l_partkey = p.p_partkey
    LEFT JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    f.region_name,
    COUNT(DISTINCT f.l_orderkey) AS total_orders,
    SUM(f.l_extendedprice * (1 - f.l_discount)) AS total_revenue,
    AVG(f.l_quantity) AS average_quantity,
    MAX(fc.total_supply_cost) AS max_supply_cost,
    MIN(fc.total_supply_cost) AS min_supply_cost
FROM 
    FullLineitem f
LEFT JOIN 
    SupplyCost fc ON f.l_partkey = fc.ps_partkey AND f.l_suppkey = fc.ps_suppkey
WHERE 
    f.l_returnflag = 'N' 
    AND f.l_shipdate IS NOT NULL
GROUP BY 
    f.region_name
HAVING 
    total_orders > 100 
    AND MAX(f.l_extendedprice) > 1000
ORDER BY 
    total_revenue DESC;
