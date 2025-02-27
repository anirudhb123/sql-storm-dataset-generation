WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AggregateSupplier AS (
    SELECT sh.s_nationkey, COUNT(*) AS supplier_count, SUM(sh.s_acctbal) AS total_acctbal
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers, 
           SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size < 25 AND p.p_retailprice IS NOT NULL
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent, MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment <> 'AUTOMOBILE'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000 OR COUNT(o.o_orderkey) > 5
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(asi.unique_suppliers, 0) AS unique_supplier_count,
    COALESCE(asi.total_availqty, 0) AS total_available_quantity,
    COALESCE(cust.order_count, 0) AS customer_order_count,
    CASE 
        WHEN asi.total_availqty IS NULL THEN 'No Parts Available'
        WHEN asi.total_availqty > 1000 THEN 'Abundant Stock'
        ELSE 'Limited Stock'
    END AS stock_availability,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY cust.total_spent DESC) AS rank_by_spending
FROM nation n
LEFT JOIN AggregateSupplier asi ON n.n_nationkey = asi.s_nationkey
LEFT JOIN CustomerOrders cust ON n.n_nationkey = cust.c_custkey
ORDER BY n.n_name, rank_by_spending;
