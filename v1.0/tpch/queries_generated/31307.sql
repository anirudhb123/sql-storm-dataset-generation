WITH RECURSIVE HighValueCustomers AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS Level
    FROM customer
    WHERE c_acctbal > 10000
    UNION ALL
    SELECT c.custkey, c.c_name, c.c_acctbal, h.Level + 1
    FROM customer c
    JOIN HighValueCustomers h ON c.c_acctbal > h.c_acctbal AND h.Level < 3
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartSupplierCount AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 10
    GROUP BY p.p_partkey
),
LineItemAggregates AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           DENSE_RANK() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM lineitem l
    WHERE l.l_shipdate < CURRENT_DATE - INTERVAL '1 year'
    GROUP BY l.l_partkey
)
SELECT n.n_name, 
       SUM(ls.revenue) AS total_revenue,
       COALESCE(hc.cust_level, 0) AS customer_level,
       p.p_name,
       ps.supplier_count
FROM NationSummary n
JOIN lineitem l ON l.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'F'
)
JOIN PartSupplierCount ps ON p.p_partkey = l.l_partkey
LEFT JOIN HighValueCustomers hc ON hc.c_custkey IN (
    SELECT DISTINCT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey = l.l_orderkey
)
JOIN Part p ON l.l_partkey = p.p_partkey
WHERE n.total_balance IS NOT NULL
GROUP BY n.n_name, hc.cust_level, p.p_name, ps.supplier_count
HAVING SUM(ls.revenue) > 500000
ORDER BY total_revenue DESC, n.n_name;
