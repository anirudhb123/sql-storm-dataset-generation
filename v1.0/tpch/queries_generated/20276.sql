WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
), FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        (SELECT SUM(ps.ps_supplycost * ps.ps_availqty)
         FROM partsupp ps
         WHERE ps.ps_partkey = p.p_partkey) AS total_supply_cost,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown'
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large' 
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
), SupplierParts AS (
    SELECT 
        ps.ps_suppkey,
        fp.p_partkey,
        RANK() OVER (PARTITION BY ps.ps_suppkey ORDER BY fp.total_supply_cost DESC) AS part_rank
    FROM 
        partsupp ps
    JOIN 
        FilteredParts fp ON ps.ps_partkey = fp.p_partkey
), HighRankedSuppliers AS (
    SELECT 
        rs.s_name, 
        fp.p_name, 
        fp.size_category, 
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        SupplierParts sp ON rs.s_suppkey = sp.ps_suppkey AND sp.part_rank = 1
    WHERE 
        rs.rn = 1
    ORDER BY 
        rs.s_acctbal DESC NULLS LAST
)
SELECT 
    hrs.s_name,
    COALESCE(hrs.p_name, 'No Parts') AS best_part,
    COUNT(hrs.p_name) OVER (PARTITION BY hrs.s_name) AS part_count_per_supplier,
    SUM(COALESCE(s.s_acctbal, 0)) AS total_account_balance
FROM 
    HighRankedSuppliers hrs
LEFT JOIN 
    supplier s ON hrs.s_name = s.s_name
WHERE 
    EXISTS (SELECT 1 FROM lineitem l WHERE l.l_suppkey = s.s_suppkey AND l.l_quantity IS NOT NULL)
GROUP BY 
    hrs.s_name, hrs.best_part
HAVING 
    COUNT(hrs.p_name) > 1
ORDER BY 
    total_account_balance DESC, best_part ASC
LIMIT 10 OFFSET 5;
