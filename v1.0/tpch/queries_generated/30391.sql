WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment,
           1 AS level
    FROM part
    WHERE p_size < 15
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment,
           ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_size = ph.p_size + 1
), SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT p.p_name, p.p_retailprice, ss.total_avail_qty, ss.avg_supply_cost,
       co.order_count, co.total_spent,
       RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
       COALESCE(co.total_spent, 0) AS customer_total_spent,
       CASE 
           WHEN co.order_count IS NULL THEN 'No Orders'
           ELSE 'Has Orders'
       END AS order_status
FROM PartHierarchy p
LEFT JOIN SupplierStats ss ON ss.total_avail_qty > 100
LEFT JOIN CustomerOrders co ON co.order_count > 0
WHERE p.p_mfgr LIKE '%a%' AND p.p_retailprice BETWEEN 10 AND 100
ORDER BY price_rank, p.p_name;
