WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 
        (SELECT AVG(o2.o_totalprice) FROM orders o2) 
),
RegionNations AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    r.n_name,
    r.r_name AS region_name,
    sc.total_cost,
    hvc.total_spent,
    r.supplier_count
FROM 
    RegionNations r
LEFT JOIN 
    SupplierCosts sc ON r.supplier_count > 0 
LEFT JOIN 
    HighValueCustomers hvc ON hvc.total_spent > 10000
WHERE 
    r.n_name IS NOT NULL
ORDER BY 
    r.r_name, sc.total_cost DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
