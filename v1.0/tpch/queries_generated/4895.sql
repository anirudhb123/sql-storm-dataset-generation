WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COALESCE(SUM(lo.order_count), 0) AS total_orders,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', ps.ps_availqty) || ' units', '; ') AS supplier_details
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    CustomerOrders lo ON s.s_nationkey = lo.c_custkey
WHERE 
    (s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000)
    OR (ps.ps_availqty < 0 OR ps.ps_supplycost IS NULL)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
ORDER BY 
    total_supply_cost DESC;
