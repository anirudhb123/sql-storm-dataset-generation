WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_purchase,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS purchase_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           n.n_name AS nation_name,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 1000 AND l.l_shipdate < CURRENT_DATE
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CombinedData AS (
    SELECT cus.c_name AS customer_name,
           sup.s_name AS supplier_name,
           (hf.total_purchase + COALESCE(sd.total_revenue, 0)) AS combined_value,
           CASE 
               WHEN hf.total_purchase IS NULL THEN 'No Purchase'
               WHEN sd.total_revenue IS NULL THEN 'No Revenue'
               ELSE 'Has Both'
           END AS purchase_revenue_status
    FROM HighValueCustomers hf
    FULL OUTER JOIN SupplierDetails sd ON hf.c_custkey = sd.s_suppkey
)
SELECT *,
       CASE 
           WHEN combined_value IS NULL THEN 'Insufficient Data'
           WHEN combined_value > 10000 THEN 'High Value'
           WHEN combined_value BETWEEN 5000 AND 10000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS value_category
FROM CombinedData
WHERE purchase_revenue_status = 'Has Both'
ORDER BY combined_value DESC, customer_name;
