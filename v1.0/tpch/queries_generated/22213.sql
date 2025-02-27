WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) OVER (PARTITION BY o.o_orderkey) AS total_returns
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
NationalSales AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT f.o_orderkey) AS order_count,
           SUM(f.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN FilteredOrders f ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = f.o_custkey)
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_partkey, p.p_name, 
       COALESCE(AVG(l.l_discount), 0) AS avg_discount, 
       COALESCE(MAX(f.o_totalprice), 0) AS max_order_value,
       COALESCE(ns.order_count, 0) AS nation_order_count,
       COALESCE(ns.total_sales, 0.00) AS nation_sales,
       CASE 
           WHEN r.rnk = 1 THEN 'Top Supplier'
           ELSE 'Other Supplier' 
       END AS supplier_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedSuppliers r ON l.l_suppkey = r.s_suppkey
LEFT JOIN NationalSales ns ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.n_nationkey))
GROUP BY p.p_partkey, p.p_name, r.rnk, ns.order_count, ns.total_sales
ORDER BY nvl(ns.total_sales, 0) DESC, p.p_partkey;
