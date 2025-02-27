WITH RECURSIVE region_summaries AS (
    SELECT 
        r_regionkey,
        r_name,
        COUNT(n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
), 
supplier_values AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        MAX(s.s_acctbal) AS max_balance,
        AVG(s.s_acctbal) AS avg_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey  
) 
SELECT 
    r.r_name,
    rs.nation_count,
    rs.nation_names,
    s.s_suppkey,
    s.total_cost,
    s.max_balance,
    s.avg_balance,
    CASE 
        WHEN s.total_cost IS NULL THEN 'NO SUPPLIER'
        WHEN s.avg_balance > 1000 THEN 'HIGH BALANCE'
        WHEN s.avg_balance BETWEEN 500 AND 1000 THEN 'MEDIUM BALANCE'
        ELSE 'LOW BALANCE'
    END AS balance_status
FROM 
    region_summaries rs
FULL OUTER JOIN 
    supplier_values s ON s.total_cost = (SELECT MAX(total_cost) FROM supplier_values WHERE max_balance IS NOT NULL)
JOIN 
    region r ON r.r_regionkey = (SELECT r_regionkey FROM nation WHERE n_nationkey IN (SELECT DISTINCT c_nationkey FROM customer WHERE c_acctbal < 0) LIMIT 1)
WHERE 
    rs.nation_count > 1 OR s.s_suppkey IS NOT NULL
ORDER BY 
    balance_status DESC, rs.nation_count, r.r_name;
