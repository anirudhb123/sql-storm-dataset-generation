WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_totalprice, o_orderdate, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.orderkey, o.o_totalprice, o.o_orderdate, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderstatus = 'O'
), 

PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS supplied_parts, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),

CustomerTotalSpend AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)

SELECT 
    p.p_name,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    COALESCE(ss.supplied_parts, 0) AS supplied_parts,
    COALESCE(ss.total_supply_cost, 0.00) AS total_supply_cost,
    ct.c_name,
    ct.total_spent,
    ROW_NUMBER() OVER (PARTITION BY ct.c_custkey ORDER BY ct.total_spent DESC) AS spend_rank
FROM PartStats ps
JOIN SupplierStats ss ON ps.p_partkey = ss.s_supplied_parts -- could also include a condition for p_brand, etc.
LEFT JOIN CustomerTotalSpend ct ON ps.p_partkey IN (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
WHERE ps.total_avail_qty > 0
ORDER BY p.p_name, total_spent DESC;
