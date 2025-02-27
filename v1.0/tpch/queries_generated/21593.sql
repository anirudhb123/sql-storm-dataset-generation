WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FrequentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        COUNT(l.l_orderkey) > 5
),
TopRegions AS (
    SELECT 
        n.n_regionkey, 
        r.r_name, 
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 10
)
SELECT 
    p.p_name,
    ps.ps_supplycost * ps.ps_availqty AS supply_value,
    COALESCE(r.r_name, 'Unknown') AS region_name,
    rs.s_name AS top_supplier,
    fo.lineitem_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rnk = 1
LEFT JOIN 
    TopRegions r ON rs.s_nationkey = r.n_nationkey
LEFT JOIN 
    FrequentOrders fo ON ps.ps_suppkey = fo.o_custkey
WHERE 
    p.p_retailprice > (
        SELECT AVG(p_retailprice) 
        FROM part 
        WHERE p_size IS NOT NULL
    ) OR 
    (p.p_container IS NULL AND p.p_size BETWEEN 1 AND 10)
ORDER BY 
    supply_value DESC, p.p_name
LIMIT 100 OFFSET 10;
