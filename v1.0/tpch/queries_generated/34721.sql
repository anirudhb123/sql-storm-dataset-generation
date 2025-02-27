WITH RECURSIVE SupplierTree AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)  -- Starting with suppliers having above-average account balance

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, st.level + 1
    FROM supplier s
    INNER JOIN SupplierTree st ON s.s_nationkey = st.s_nationkey  -- Joining on nation to find suppliers in the same nation
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)    -- Ensure we are only including above-average suppliers
),
AggregatedOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) as total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
CustomerDetail AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_purchase,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'  -- Filtering by last year
    GROUP BY c.c_custkey, c.c_name
),
NationSummary AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS total_customers, 
           SUM(COALESCE(cd.total_purchase, 0)) AS total_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN CustomerDetail cd ON c.c_custkey = cd.c_custkey
    GROUP BY n.n_name
)
SELECT ns.n_name,
       ns.total_customers,
       ns.total_revenue,
       st.s_name,
       st.s_acctbal,
       CASE
           WHEN ns.total_revenue IS NOT NULL THEN ns.total_revenue - COALESCE(AVG(st.s_acctbal) OVER(), 0)
           ELSE NULL
       END AS revenue_to_account_balance_difference
FROM NationSummary ns
LEFT JOIN SupplierTree st ON ns.total_customers > (SELECT COUNT(*) FROM customer) / 10 -- Get suppliers in nations with more than 10% of all customers
WHERE ns.total_revenue IS NOT NULL
ORDER BY ns.total_revenue DESC;
