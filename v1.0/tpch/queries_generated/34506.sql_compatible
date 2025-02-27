
WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > 50000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sc.depth + 1
    FROM supplier s
    JOIN SupplierCTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE sc.depth < 5
),
OrderStats AS (
    SELECT o.o_orderkey, COUNT(DISTINCT l.l_suppkey) AS supplier_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT r.r_name, n.n_name, SUM(os.total_revenue) AS total_revenue,
       COUNT(DISTINCT si.s_suppkey) AS supplier_count,
       COALESCE(SUM(si.s_acctbal), 0) AS total_acct_balance,
       CASE WHEN SUM(os.total_revenue) > 100000 THEN 'High Revenue' ELSE 'Low Revenue' END AS revenue_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierCTE si ON n.n_nationkey = si.s_suppkey
JOIN OrderStats os ON n.n_nationkey = os.o_orderkey
LEFT JOIN PartSupplierInfo psi ON psi.rn = 1
GROUP BY r.r_name, n.n_name
HAVING COUNT(si.s_suppkey) > 0
ORDER BY total_revenue DESC, r.r_name ASC;
