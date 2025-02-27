WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
RankingSupply AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           SUM(ps.ps_supplycost) / COUNT(DISTINCT ps.ps_suppkey) AS avg_supply_cost,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS supply_rank
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus != 'C'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, 
           COALESCE(RS.total_avail_qty, 0) AS total_available,
           COALESCE(RS.avg_supply_cost, 0) AS avg_supply_cost,
           COALESCE(CO.total_spent, 0) AS total_spent
    FROM part p
    LEFT JOIN RankingSupply RS ON p.p_partkey = RS.ps_partkey
    LEFT JOIN CustomerOrders CO ON RS.ps_suppkey = CO.c_custkey
)
SELECT p.p_name, p.p_mfgr, 
       COALESCE(p.total_available, 0) AS total_avail_qty,
       COALESCE(p.avg_supply_cost, 0) AS avg_supply_cost,
       COALESCE(p.total_spent, 0) AS total_spent,
       n.n_name AS nation_name
FROM PartSupplierDetails p
JOIN nation n ON p.p_partkey = n.n_nationkey
WHERE (p.total_spent > 1000 OR p.avg_supply_cost < 20)
AND p.total_available IS NOT NULL
ORDER BY total_spent DESC, avg_supply_cost ASC
LIMIT 100;
