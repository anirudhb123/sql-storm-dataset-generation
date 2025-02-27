WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           NULL AS parent_suppkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey AS parent_suppkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) * 0.5
),
highlighted_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),

customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

part_supplier_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)

SELECT c.c_name AS customer_name, 
       ps.part_name, 
       pl.total_avail_qty,
       pl.avg_supply_cost,
       co.total_orders, 
       co.total_spent
FROM (SELECT p.p_partkey, p.p_name AS part_name, 
             PS.total_avail_qty, PS.avg_supply_cost
      FROM highlighted_parts p
      JOIN part_supplier_summary PS ON p.p_partkey = PS.ps_partkey
      WHERE p.rn = 1) AS pl
JOIN customer_order_summary co ON co.total_spent > 10000
LEFT JOIN customer c ON c.c_custkey = co.c_custkey
WHERE c.c_custkey IN (SELECT c2.c_custkey 
                      FROM customer c2 
                      WHERE c2.c_acctbal IS NOT NULL 
                        AND c2.c_acctbal > (SELECT AVG(c3.c_acctbal) FROM customer c3))
ORDER BY c.c_name, pl.part_name;
