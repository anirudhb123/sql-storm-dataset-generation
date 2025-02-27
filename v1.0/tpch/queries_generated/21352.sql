WITH RECURSIVE NationalSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) + ns.total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN NationalSuppliers ns ON ns.s_nationkey = s.s_nationkey
    WHERE ns.s_suppkey IS NOT NULL
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_linenumber) AS line_item_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY total_price DESC) AS rank_order
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_price) AS total_spent
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PriceComparison AS (
    SELECT n.n_nationkey, n.n_name, 
           AVG(cs.total_spent) AS avg_spending,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN CustomerSpending cs ON cs.c_custkey = s.s_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name AS region_name, 
       COALESCE(pc.avg_spending, 0) AS average_spending,
       pc.supplier_count,
       CASE 
           WHEN pc.avg_spending > 1000 THEN 'High spender'
           WHEN pc.avg_spending BETWEEN 500 AND 1000 THEN 'Medium spender'
           ELSE 'Low spender'
       END AS spending_category
FROM region r
LEFT JOIN PriceComparison pc ON r.r_regionkey = pc.n_nationkey
WHERE NULLIF(pc.avg_spending, 0) IS NOT NULL
ORDER BY region_name, average_spending DESC;

