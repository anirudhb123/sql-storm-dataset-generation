WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), 
PartSupplierInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        COALESCE(NULLIF(p.p_container, ''), 'UNKNOWN') AS container_type,
        CASE 
            WHEN ps.ps_supplycost > 100 THEN 'HIGH COST'
            ELSE 'LOW COST'
        END AS cost_category
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT ps.p_partkey) AS part_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
    ARRAY_AGG(DISTINCT CONCAT(s.s_name, ' - ', ps.cost_category)) FILTER (WHERE s.rn <= 3) AS top_suppliers_details,
    COALESCE(MAX(co.total_spent), 0) AS max_customer_spent,
    COUNT(NULLIF(co.c_custkey, 0)) AS customer_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    PartSupplierInfo ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    CustomerOrders co ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = co.c_custkey) 
WHERE 
    (ps.ps_availqty IS NOT NULL AND ps.ps_availqty > 0) 
    OR (s.s_acctbal IS NULL AND r.r_comment LIKE '%important%')
GROUP BY 
    r.r_name
ORDER BY 
    total_supply_value DESC
LIMIT 10;
