WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS part_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
),
SupplierAnalysis AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value,
        CASE WHEN SUM(ps.ps_availqty) > 1000 THEN 'High' 
             WHEN SUM(ps.ps_availqty) BETWEEN 500 AND 1000 THEN 'Medium' 
             ELSE 'Low' 
        END AS supply_category
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    rp.p_name,
    rp.total_cost,
    CASE WHEN rp.part_rank <= 3 THEN 'Top Parts' ELSE 'Other Parts' END AS part_category,
    sa.supplier_value,
    sa.supply_category
FROM 
    CustomerOrders c
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    RankedParts rp ON l.l_partkey = rp.p_partkey
FULL OUTER JOIN 
    SupplierAnalysis sa ON l.l_suppkey = sa.s_suppkey 
WHERE 
    (c.c_name LIKE 'A%' OR sa.supply_category = 'High') AND 
    (rp.total_cost IS NOT NULL AND sa.supplier_value > 1000 OR sa.supplier_value IS NULL)
ORDER BY 
    c.c_name, rp.total_cost DESC
LIMIT 100 OFFSET 50;
