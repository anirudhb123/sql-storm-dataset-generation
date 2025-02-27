WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal - 50, s.s_comment
    FROM supplier s
    JOIN SupplierCTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE s.s_acctbal < sc.s_acctbal
),
OrderTotals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
PartSupplied AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FinalResult AS (
    SELECT p.p_name, p.p_brand, COALESCE(s.s_name, 'No Supplier') AS supplier_name, 
           pt.total_available, ot.total_sales,
           CASE 
               WHEN cs.order_count IS NULL THEN 'No Orders' 
               ELSE CONCAT(cs.order_count, ' Orders')
           END AS order_info
    FROM part p
    LEFT JOIN PartSupplied pt ON p.p_partkey = pt.ps_partkey
    LEFT JOIN SupplierCTE s ON pt.total_available > 10
    LEFT JOIN OrderTotals ot ON ot.o_orderkey IN (SELECT o.o_orderkey FROM orders o 
                                                   JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                                   WHERE l.l_partkey = p.p_partkey)
    LEFT JOIN CustomerSales cs ON cs.total_spent > 10000
    ORDER BY p.p_name
)
SELECT *
FROM FinalResult
WHERE supplier_name IS NOT NULL
OR total_sales IS NOT NULL
ORDER BY total_available DESC, total_sales DESC;
