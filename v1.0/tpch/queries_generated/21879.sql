WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           c.c_nationkey,
           c.c_acctbal,
           CASE 
               WHEN c.c_acctbal > 10000 THEN 'High Value'
               WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           COUNT(l.l_orderkey) AS total_line_items,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
FilteredOrders AS (
    SELECT o,
           c.c_name,
           COALESCE(rn.r_name, 'Unknown Region') AS region_name,
           os.total_order_value
    FROM OrderSummary os
    INNER JOIN customer c ON os.o_custkey = c.c_custkey
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region rn ON n.n_regionkey = rn.r_regionkey
    WHERE os.total_order_value > (
        SELECT AVG(total_order_value)
        FROM OrderSummary
    )
)
SELECT fo.c_name AS customer_name,
       fo.total_order_value,
       sr.s_name AS top_supplier,
       CAST(fo.total_order_value AS varchar) || ' USD' AS formatted_value,
       COUNT(DISTINCT fo.o_orderkey) OVER (PARTITION BY fo.region_name) AS orders_in_region,
       CASE 
           WHEN sr.rank = 1 THEN 'Top Supplier'
           ELSE 'Other Supplier'
       END AS supplier_rank
FROM FilteredOrders fo
LEFT JOIN RankedSuppliers sr ON sr.rank = 1 AND sr.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_brand LIKE 'Brand#%'
)
WHERE fo.total_order_value IS NOT NULL
ORDER BY fo.total_order_value DESC, customer_name
FETCH FIRST 50 ROWS ONLY;
