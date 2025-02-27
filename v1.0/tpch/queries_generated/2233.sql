WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
), CustomerSummary AS (
    SELECT c.c_custkey, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           MAX(o.o_orderdate) AS last_order_date,
           CASE 
               WHEN SUM(o.o_totalprice) > 1000 THEN 'VIP'
               ELSE 'Regular'
           END AS customer_type
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), PartSupplier AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT n.n_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(cs.total_spent) AS avg_spent,
       SUM(CASE WHEN cs.customer_type = 'VIP' THEN 1 ELSE 0 END) AS vip_count,
       AVG(CASE 
               WHEN lo.o_orderkey IS NOT NULL THEN lo.l_extendedprice
               ELSE NULL 
           END) AS avg_line_item_price,
       (SELECT COUNT(*) 
        FROM lineitem l 
        WHERE l.l_returnflag = 'Y' 
          AND l.l_shipdate < CURRENT_DATE) AS total_returns
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN CustomerSummary cs ON s.s_suppkey = cs.c_custkey
LEFT JOIN RankedOrders lo ON cs.order_count > 0 AND cs.last_order_date > DATE '2023-01-01'
LEFT JOIN PartSupplier ps ON ps.ps_partkey = cs.c_custkey
WHERE n.n_name LIKE 'A%' 
  AND (cs.total_spent IS NOT NULL OR cs.order_count > 5)
GROUP BY n.n_name
HAVING COUNT(DISTINCT cs.c_custkey) > 10
ORDER BY avg_spent DESC;
