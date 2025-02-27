WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           NULL::integer AS parent_suppkey, 
           s.s_acctbal AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           sh.s_suppkey AS parent_suppkey, 
           sh.total_acctbal + s.s_acctbal AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.parent_suppkey
    WHERE s.s_acctbal > 0
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost > 50
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
NationRegionData AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT sh.s_name AS supplier_name, 
       sh.total_acctbal AS total_account_balance, 
       ps.p_name AS part_name, 
       ps.ps_supplycost AS supply_cost, 
       os.total_sales AS order_total
FROM SupplierHierarchy sh
LEFT JOIN PartSupplier ps ON ps.p_partkey = (SELECT ps_partkey 
                                              FROM partsupp 
                                              ORDER BY ps_supplycost DESC 
                                              LIMIT 1)
LEFT JOIN OrderSummary os ON os.o_orderkey = (SELECT o.o_orderkey
                                              FROM orders o 
                                              JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                              WHERE o.o_orderstatus = 'O' 
                                              ORDER BY total_sales DESC 
                                              LIMIT 1)
WHERE sh.total_acctbal IS NOT NULL
ORDER BY sh.total_acctbal DESC, order_total DESC
LIMIT 10;
