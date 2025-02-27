WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 0 AS level
    FROM part
    WHERE p_size < 20
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice * 0.9, h.level + 1
    FROM part p
    JOIN PartHierarchy h ON p.p_size >= 20 AND p.p_partkey = h.p_partkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) as total_avail_qty, 
           COUNT(DISTINCT p.p_partkey) as unique_parts_supplied
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) as order_count,
           SUM(o.o_totalprice) as total_spent
    FROM customer c 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ph.p_partkey, ph.p_name, ph.p_size, 
    ss.total_avail_qty, cs.order_count, cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders' 
        WHEN cs.total_spent < 1000 THEN 'Low Spending' 
        ELSE 'High Spending' 
    END AS customer_spending_category,
    ROUND(ph.p_retailprice * 0.9, 2) AS discounted_price
FROM PartHierarchy ph
FULL OUTER JOIN SupplierStats ss ON ph.p_partkey = ss.s_suppkey
FULL OUTER JOIN CustomerOrders cs ON ph.p_partkey = cs.c_custkey
WHERE (ss.total_avail_qty IS NOT NULL OR cs.order_count > 0) 
  AND (ph.p_retailprice > 50 OR ph.p_size < 15)
ORDER BY ph.p_name, customer_spending_category DESC;
