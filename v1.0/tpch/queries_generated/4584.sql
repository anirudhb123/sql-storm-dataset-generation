WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) as rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 5000
), SupplierSummary AS (
    SELECT 
        ps_partkey, 
        COUNT(*) as supplier_count,
        SUM(ps_supplycost) as total_supply_cost
    FROM 
        RankedSuppliers 
    WHERE 
        rank <= 3
    GROUP BY 
        ps_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(ss.supplier_count, 0) as top_supplier_count, 
    COALESCE(ss.total_supply_cost, 0) as supplier_cost_sum,
    (SELECT AVG(l.l_extendedprice) 
      FROM lineitem l 
      WHERE l.l_partkey = p.p_partkey) as avg_price,
    (SELECT STRING_AGG(DISTINCT s.s_name, ', ') 
      FROM partsupp ps 
      JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
      WHERE ps.ps_partkey = p.p_partkey) as supplier_names
FROM 
    part p
LEFT JOIN 
    SupplierSummary ss ON p.p_partkey = ss.ps_partkey
WHERE 
    (p.p_size = 18 AND p.p_retailprice BETWEEN 100.00 AND 200.00) 
    OR (p.p_type LIKE '%plastic%')
ORDER BY 
    p.p_partkey;
