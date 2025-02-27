WITH SupplierAggregate AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
NationSupplier AS (
    SELECT n.n_name, sa.total_acctbal
    FROM nation n
    JOIN SupplierAggregate sa ON n.n_nationkey = sa.s_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ns.n_name, COUNT(os.o_orderkey) AS order_count, 
       SUM(os.total_sales) AS total_sales,
       AVG(sa.total_acctbal) AS avg_supplier_balance
FROM NationSupplier ns
JOIN OrderSummary os ON ns.n_name = (SELECT n_name FROM nation WHERE n_regionkey = (SELECT n_regionkey FROM nation WHERE n_name = ns.n_name LIMIT 1))
JOIN Supplier s ON s.s_nationkey = ns.n_nationkey
JOIN SupplierAggregate sa ON sa.s_nationkey = s.s_nationkey
GROUP BY ns.n_name
ORDER BY total_sales DESC
LIMIT 10;
