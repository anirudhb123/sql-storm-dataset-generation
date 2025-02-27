WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY o.o_orderkey
),
DonationSummary AS (
    SELECT ns.n_name, SUM(os.total_revenue) AS total_donations
    FROM NationSummary ns
    LEFT JOIN OrderDetails os ON ns.supplier_count > 0
    GROUP BY ns.n_name
)

SELECT dh.n_name AS nation_name, dh.supplier_count, 
       CASE 
           WHEN dh.supplier_count > 5 THEN 'High Supplier Count'
           ELSE 'Low Supplier Count'
       END AS supplier_category,
       COALESCE(ds.total_donations, 0) AS total_revenue_from_orders,
       ROW_NUMBER() OVER (PARTITION BY dh.n_name ORDER BY dh.supplier_count DESC) AS rn
FROM NationSummary dh
LEFT JOIN DonationSummary ds ON dh.n_name = ds.n_name
WHERE dh.supplier_count IS NOT NULL
ORDER BY dh.n_name ASC;
