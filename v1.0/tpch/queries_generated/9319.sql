WITH RECURSIVE RegionHierarchy AS (
    SELECT r.r_regionkey, r.r_name, 0 AS level
    FROM region r
    UNION ALL
    SELECT r.r_regionkey, r.r_name, level + 1
    FROM nation n
    INNER JOIN RegionHierarchy rh ON n.n_regionkey = rh.r_regionkey
    JOIN region r ON r.r_regionkey = n.n_regionkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON o.o_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopProducts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM part p
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey, p.p_name
    ORDER BY revenue DESC
    LIMIT 10
)
SELECT rh.r_name AS region_name,
       SUM(cs.order_count) AS total_customers,
       SUM(sd.total_cost) AS total_supplier_cost,
       tp.p_name AS top_product,
       tp.revenue
FROM RegionHierarchy rh
JOIN CustomerOrderSummary cs ON cs.order_count > 0
JOIN SupplierDetails sd ON sd.total_cost > 0
JOIN TopProducts tp ON tp.revenue > 0
GROUP BY rh.r_name, tp.p_name, tp.revenue
ORDER BY rh.r_name, tp.revenue DESC;
