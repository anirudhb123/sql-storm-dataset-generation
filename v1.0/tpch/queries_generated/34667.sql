WITH RECURSIVE SupplierTree AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, st.level + 1
    FROM supplier s
    INNER JOIN SupplierTree st ON s.s_nationkey = st.s_nationkey
    WHERE s.s_acctbal > 1000 AND st.level < 5
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY o.o_custkey
),
CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, COALESCE(os.total_revenue, 0) AS total_revenue, ROW_NUMBER() OVER (ORDER BY COALESCE(os.total_revenue, 0) DESC) AS revenue_rank
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
),
NationSupplier AS (
    SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
)
SELECT DISTINCT 
    c.c_name AS customer_name,
    ns.n_name AS nation_name,
    COALESCE(cr.total_revenue, 0) AS total_revenue,
    st.level AS supplier_level,
    CASE WHEN cr.revenue_rank <= 10 THEN 'Top Customer' ELSE 'Regular Customer' END AS customer_status,
    ns.total_supply_cost
FROM CustomerRevenue cr
FULL OUTER JOIN NationSupplier ns ON cr.c_custkey IS NULL OR cr.c_custkey = 0
LEFT JOIN SupplierTree st ON cr.c_custkey = st.s_suppkey
WHERE ns.total_supply_cost IS NOT NULL
AND (cr.total_revenue > 5000 OR cr.c_custkey IS NULL)
ORDER BY total_revenue DESC, nation_name;
