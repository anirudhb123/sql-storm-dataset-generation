WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupply AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, ps.total_avail_qty, ps.total_supply_cost,
           RANK() OVER (ORDER BY ps.total_supply_cost DESC) AS rank
    FROM PartSupply ps
    JOIN part p ON ps.p_partkey = p.p_partkey
)
SELECT c.c_name,
       CASE 
           WHEN co.order_count > 0 THEN 'Active'
           ELSE 'Inactive'
       END AS customer_status,
       rp.rank,
       rp.total_avail_qty,
       rp.total_supply_cost
FROM CustomerOrderStats co
FULL OUTER JOIN RankedParts rp ON co.order_count > 0 AND rp.rank <= 5
WHERE co.order_count IS NOT NULL OR rp.total_supply_cost IS NOT NULL
ORDER BY rp.rank;
