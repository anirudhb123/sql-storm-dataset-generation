
WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS Level 
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sc.Level + 1 
    FROM 
        supplier s
    JOIN 
        SupplyChain sc ON sc.s_suppkey = s.s_suppkey
    WHERE 
        sc.Level < 5
),
AveragePrice AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost 
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.r_name, 'Unknown') AS region_name,
    AVG(ap.avg_supply_cost) AS avg_supply_cost,
    COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discount_revenue
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    AveragePrice ap ON p.p_partkey = ap.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
WHERE 
    p.p_size IN (5, 10, 15)
GROUP BY 
    p.p_partkey, 
    p.p_name,
    r.r_name
ORDER BY 
    avg_supply_cost DESC, 
    high_value_order_count DESC;
