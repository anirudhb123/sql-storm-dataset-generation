WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 3
),
PartPricing AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    LEFT OUTER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    nh.n_name AS nation_name,
    pp.p_name AS part_name,
    pp.p_retailprice,
    pp.total_supply_cost,
    co.order_count,
    co.total_spent,
    sh.level AS supplier_level
FROM PartPricing pp
JOIN SupplierHierarchy sh ON pp.p_partkey = sh.s_suppkey
JOIN nation nh ON sh.s_nationkey = nh.n_nationkey
JOIN CustomerOrders co ON co.order_count > 10
WHERE pp.price_rank = 1
  AND pp.total_supply_cost < 500
ORDER BY co.total_spent DESC, sh.level ASC
LIMIT 50;
