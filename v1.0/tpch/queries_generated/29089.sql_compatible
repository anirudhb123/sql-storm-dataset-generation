
WITH SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_acctbal AS acct_balance,
        r.r_name AS region_name,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        JOIN region r ON n.n_regionkey = r.r_regionkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 10000
        AND r.r_name LIKE 'N%'
    GROUP BY 
        s.s_name, s.s_acctbal, r.r_name
)
SELECT 
    sd.s_name,
    sd.acct_balance,
    sd.region_name,
    sd.part_count,
    sd.total_supply_cost,
    sd.part_names,
    CASE 
        WHEN sd.total_supply_cost > 500000 THEN 'High Value'
        WHEN sd.total_supply_cost BETWEEN 200000 AND 500000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    SupplierDetails sd
ORDER BY 
    sd.total_supply_cost DESC;
