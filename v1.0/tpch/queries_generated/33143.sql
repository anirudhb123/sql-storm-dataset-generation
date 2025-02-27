WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal < ch.c_acctbal
),
OrderTotals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_available, 
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, ot.total_sales, 
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY ot.total_sales DESC) as rank
    FROM orders o
    JOIN OrderTotals ot ON o.o_orderkey = ot.o_orderkey
),
NationSales AS (
    SELECT n.n_name, SUM(ot.total_sales) AS total_sales_by_nation
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN OrderTotals ot ON o.o_orderkey = ot.o_orderkey
    GROUP BY n.n_name
),
SupplierSales AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_total
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
)
SELECT ch.c_name, ch.level, ns.n_name, ns.total_sales_by_nation,
       ss.supplier_total, ss.unique_parts, ss.total_available
FROM CustomerHierarchy ch
LEFT JOIN NationSales ns ON ns.total_sales_by_nation IS NOT NULL
LEFT JOIN SupplierStats ss ON ss.total_available IS NOT NULL
WHERE (ch.level = 2 AND ch.c_acctbal > 2000)
   OR (ch.level = 1 AND ch.c_acctbal < 1500)
ORDER BY ch.c_name, ns.n_name;
