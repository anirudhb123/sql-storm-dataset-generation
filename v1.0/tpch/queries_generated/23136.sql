WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
PartSupplierStats AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemSummary AS (
    SELECT l.l_orderkey,
           SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rn
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
    GROUP BY l.l_orderkey
),
OrderStatus AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           os.level,
           COALESCE(ns.total_price, 0) AS net_total_price
    FROM orders o
    LEFT JOIN LineItemSummary ns ON o.o_orderkey = ns.l_orderkey
    LEFT JOIN NationHierarchy nh ON o.o_custkey = nh.n_nationkey
)
SELECT p.p_partkey,
       p.p_name,
       p.p_retailprice,
       COALESCE(ps.total_available, 0) AS total_available,
       COALESCE(ps.avg_supply_cost, 0) AS avg_supply_cost,
       COALESCE(oss.net_total_price, 0) AS net_total_price,
       CASE 
           WHEN oss.o_orderstatus IS NULL THEN 'NO ORDERS'
           WHEN oss.o_orderstatus = 'O' THEN 'OPEN'
           ELSE 'CLOSED' 
       END AS order_status_description
FROM part p
LEFT JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN OrderStatus oss ON p.p_partkey = oss.o_orderkey
WHERE (ps.total_available IS NOT NULL OR ps.avg_supply_cost IS NOT NULL)
  AND (oss.net_total_price > 0 OR oss.o_orderstatus IS NULL)
ORDER BY p.p_partkey, order_status_description DESC
FETCH FIRST 100 ROWS ONLY;
