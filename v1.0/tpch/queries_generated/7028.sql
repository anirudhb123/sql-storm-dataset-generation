WITH NationSupplier AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acct_bal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PopularParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 1000
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT ns.n_name, pp.total_avail_qty, cos.order_count, cos.avg_order_value
FROM NationSupplier ns
JOIN PopularParts pp ON ns.n_name IN (SELECT s.n_name FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 25)))
JOIN CustomerOrderSummary cos ON ns.n_name IN (SELECT n.n_name FROM nation n JOIN customer c ON n.n_nationkey = c.c_nationkey WHERE c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderdate > '2022-01-01'))
ORDER BY ns.n_name, pp.total_avail_qty DESC;
