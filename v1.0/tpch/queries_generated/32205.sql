WITH RECURSIVE Supp_CTE AS (
    SELECT s_suppkey, s_nationkey, s_name, s_acctbal, 
           CASE 
               WHEN s_acctbal IS NULL THEN 0 
               ELSE s_acctbal 
           END AS adjusted_acctbal
    FROM supplier
    WHERE s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_nationkey, s.s_name, s.s_acctbal,
           CASE 
               WHEN s.s_acctbal IS NULL THEN 0 
               ELSE s.s_acctbal 
           END
    FROM supplier s
    JOIN Supp_CTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.adjusted_acctbal
),
Orders_Summary AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS customer_count,
           DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
Part_Stats AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
Nation_Stats AS (
   SELECT n.n_nationkey, n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(c.c_acctbal) AS total_customer_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    p.p_name,
    ps.total_available,
    ps.avg_supply_cost,
    ns.supplier_count,
    ns.total_customer_acctbal,
    os.total_revenue,
    os.customer_count,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Exists' 
    END AS revenue_status
FROM part p
LEFT JOIN Part_Stats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN Nation_Stats ns ON ns.n_nationkey = (SELECT n_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT MIN(s_suppkey) FROM supplier))
LEFT JOIN Orders_Summary os ON os.o_orderkey = (SELECT o_orderkey FROM orders ORDER BY o_orderdate LIMIT 1)
WHERE ps.total_available IS NOT NULL AND ns.total_customer_acctbal > 10000
ORDER BY revenue_rank DESC NULLS LAST;
