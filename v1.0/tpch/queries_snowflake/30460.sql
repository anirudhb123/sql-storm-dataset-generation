WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS depth
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, depth + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
AvgSupplierCost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_cost
    FROM partsupp
    GROUP BY ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    nt.n_name AS nation_name,
    r.r_name AS region_name,
    CASE 
        WHEN AVG_SC.avg_cost IS NULL THEN 0 
        ELSE AVG_SC.avg_cost 
    END AS avg_supply_cost,
    C.total_spent
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation nt ON s.s_nationkey = nt.n_nationkey
LEFT JOIN 
    region r ON nt.n_regionkey = r.r_regionkey
LEFT JOIN 
    AvgSupplierCost AVG_SC ON p.p_partkey = AVG_SC.ps_partkey
LEFT JOIN 
    CustomerOrders C ON s.s_nationkey = C.c_custkey
WHERE 
    p.p_retailprice >= 100.00
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    p.p_name, nt.n_name, r.r_name, AVG_SC.avg_cost, C.total_spent
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    revenue DESC;
