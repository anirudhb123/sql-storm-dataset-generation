WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_quantity * (1 - l.l_discount)) AS total_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrdersSummary AS (
    SELECT o.o_orderdate, SUM(o.o_totalprice) AS total_sales,
           AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderdate
)
SELECT 
    r.r_name,
    SUM(co.total_spending) AS total_customer_spending,
    COUNT(DISTINCT co.c_custkey) AS number_of_customers,
    COUNT(DISTINCT l.l_orderkey) AS total_line_items,
    os.total_sales,
    os.avg_order_value,
    sh.level
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN TotalLineItems l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN OrdersSummary os ON os.o_orderdate = o.o_orderdate
WHERE r.r_name IS NOT NULL AND co.total_orders > 0 OR l.total_quantity IS NOT NULL
GROUP BY r.r_name, sh.level, os.avg_order_value
ORDER BY total_customer_spending DESC, r.r_name;
