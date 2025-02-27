WITH RECURSIVE CTE_Summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region,
        SUM(CASE WHEN c.c_acctbal IS NULL THEN 0 ELSE c.c_acctbal END) AS total_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
    HAVING 
        SUM(CASE WHEN c.c_acctbal IS NOT NULL THEN c.c_acctbal ELSE 0 END) > 10000
    ORDER BY 
        total_acctbal DESC
),
CTE_Supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 100.00
    AND 
        ps.ps_availqty >= 1
)
SELECT 
    region,
    n.n_name,
    SUM(COALESCE(ps_total, 0)) AS total_supplycost,
    COUNT(DISTINCT CASE WHEN rn = 1 THEN p.p_partkey END) AS unique_parts,
    COUNT(DISTINCT o.o_orderkey) AS unique_orders
FROM 
    CTE_Summary n
LEFT JOIN 
    CTE_Supplier ps ON n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_nustkey IN (SELECT DISTINCT o.o_custkey FROM orders o))
LEFT JOIN 
    orders o ON o.o_orderkey IN (SELECT o.o_orderkey FROM lineitem l WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31')
GROUP BY 
    region, n.n_name
HAVING 
    SUM(COALESCE(ps_total, 0)) > (SELECT AVG(supply_cost) FROM (SELECT DISTINCT ps.ps_supplycost AS supply_cost FROM CTE_Supplier ps WHERE ps.rn = 1) AS AvgCost) OR 
    n.n_name IS NULL
ORDER BY 
    total_supplycost DESC
LIMIT 10
OFFSET 5;
