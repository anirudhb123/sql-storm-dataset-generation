WITH SupplierDetails AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank,
           CASE 
               WHEN s_acctbal IS NULL THEN 'No Balance' 
               WHEN s_acctbal < 1000 THEN 'Low Balance'
               ELSE 'Sufficient Balance' 
           END AS balance_status
    FROM supplier 
), 
HighValueOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate,
           SUM(l_extendedprice * (1 - l_discount)) AS total_amount,
           COUNT(DISTINCT l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o_orderdate >= '2023-01-01' AND o_orderstatus = 'O'
    GROUP BY o_orderkey, o_custkey, o_totalprice, o_orderdate
    HAVING SUM(l_extendedprice * (1 - l_discount)) > 5000
),
TopNationSuppliers AS (
    SELECT nsn.n_nationkey, nsn.n_name, SUM(sd.s_acctbal) AS total_acctbal
    FROM nation nsn
    JOIN SupplierDetails sd ON nsn.n_nationkey = sd.s_nationkey
    WHERE sd.rank <= 3 AND sd.balance_status != 'No Balance'
    GROUP BY nsn.n_nationkey, nsn.n_name
)
SELECT r.r_regionkey, r.r_name,
       COALESCE(SUM(hvo.total_amount), 0) AS regional_total,
       COALESCE(SUM(tns.total_acctbal), 0) AS supplier_total,
       STRING_AGG(DISTINCT tns.n_name, ', ') AS supplier_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN TopNationSuppliers tns ON n.n_nationkey = tns.n_nationkey
LEFT JOIN HighValueOrders hvo ON tns.n_nationkey = hvo.o_custkey
WHERE r.r_name LIKE 'E%' OR tns.total_acctbal IS NOT NULL
GROUP BY r.r_regionkey, r.r_name
HAVING SUM(COALESCE(hvo.total_amount, 0)) > 10000 OR COUNT(DISTINCT tns.n_nationkey) > 2
ORDER BY regional_total DESC NULLS LAST;
