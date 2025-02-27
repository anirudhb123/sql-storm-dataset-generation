WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_mfgr, p_brand, p_type, p_size, p_retailprice, p_comment, 0 AS level
    FROM part
    WHERE p_size < 50
    UNION ALL
    SELECT p.p_partkey, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = (p.p_partkey + ph.level)
    WHERE ph.level < 5
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 1000.00
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT ph.p_mfgr, ph.p_type, COUNT(DISTINCT si.s_suppkey) AS supplier_count, 
       SUM(os.total_sales) AS total_sales, AVG(si.s_acctbal) AS average_acct_bal
FROM part_hierarchy ph
JOIN supplier_info si ON ph.p_size = (si.s_suppkey % 1000) 
JOIN order_summary os ON os.total_sales > 5000
GROUP BY ph.p_mfgr, ph.p_type
HAVING COUNT(DISTINCT si.s_suppkey) > 5
ORDER BY total_sales DESC, average_acct_bal DESC;
