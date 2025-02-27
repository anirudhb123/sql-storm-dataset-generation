WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_type, 
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
)
SELECT
    r.r_name,
    pd.p_name,
    pd.total_supply_cost,
    COALESCE(rs.s_name, 'Unknown Supplier') AS s_name,
    CASE 
        WHEN pd.supplier_count = 0 THEN 'No Suppliers Available'
        ELSE CONCAT('Suppliers Available: ', pd.supplier_count)
    END AS supplier_info,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY pd.total_supply_cost DESC) AS rank_by_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rnk <= 3
JOIN PartDetails pd ON pd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM PartDetails)
WHERE r.r_regionkey IN (SELECT DISTINCT n.n_regionkey FROM nation n WHERE n.n_comment LIKE '%north%')
ORDER BY r.r_name, pd.total_supply_cost DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM part) * RANDOM() / 100; 
