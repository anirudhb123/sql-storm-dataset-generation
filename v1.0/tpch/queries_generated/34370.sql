WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
ProductStats AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, AVG(l.l_extendedprice) AS avg_extended_price, SUM(l.l_discount) AS total_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(p.total_cost) AS total_product_cost,
    SUM(cus.total_spent) AS total_customer_spent,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(cus.total_spent) DESC) AS rank_by_spending
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN ProductStats p ON ps.ps_partkey = p.p_partkey
LEFT JOIN CustomerOrderSummary cus ON s.s_suppkey = cus.c_custkey
LEFT JOIN LineItemAnalysis li ON cus.order_count = li.l_orderkey
WHERE s.s_acctbal IS NOT NULL
GROUP BY r.r_name, n.n_name, s.s_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY rank_by_spending;
