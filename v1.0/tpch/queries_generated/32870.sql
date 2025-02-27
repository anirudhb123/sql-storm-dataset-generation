WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           s.s_acctbal,
           ps.ps_availqty * ps.ps_supplycost AS supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           s.s_acctbal,
           ps.ps_availqty * ps.ps_supplycost AS supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON sc.s_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
AggregatedValues AS (
    SELECT n.n_name,
           SUM(sc.supply_value) AS total_supply_value,
           COUNT(s.s_suppkey) AS supplier_count,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(sc.supply_value) DESC) AS supply_rank
    FROM nation n
    LEFT JOIN SupplyChain sc ON n.n_nationkey = sc.s_nationkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
FilteredResults AS (
    SELECT n.n_name,
           a.total_supply_value,
           a.supplier_count,
           CASE WHEN a.total_supply_value IS NULL THEN 'No Supply' 
                ELSE CONCAT(n.n_name, ' Supply Total: ', CAST(a.total_supply_value AS VARCHAR)) END AS supply_summary
    FROM nation n
    JOIN AggregatedValues a ON n.n_name = a.n_name
    WHERE (a.supplier_count > 0 OR a.total_supply_value IS NOT NULL)
)
SELECT fr.n_name,
       fr.total_supply_value,
       fr.supplier_count,
       fr.supply_summary
FROM FilteredResults fr
WHERE fr.supplier_count >= (
    SELECT COUNT(*) FROM supplier) / 10
ORDER BY fr.total_supply_value DESC
LIMIT 10;
