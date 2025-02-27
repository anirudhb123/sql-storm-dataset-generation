WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT DISTINCT ps_suppkey FROM partsupp WHERE ps_availqty < 40)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartStats AS (
    SELECT p.p_partkey, 
           COUNT(DISTINCT ps.s_suppkey) AS supplier_count, 
           AVG(ps.ps_supplycost) AS avg_supply_cost, 
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderStats AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT o.o_custkey) AS customer_count,
           MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE (o.o_orderdate >= '2023-01-01' AND o.o_orderdate <= '2023-12-31')
      AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
    GROUP BY o.o_orderkey
),
NationStats AS (
    SELECT n.n_nationkey, 
           COUNT(DISTINCT s.s_suppkey) AS nation_supplier_count,
           SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
)
SELECT DISTINCT 
    p.p_name, 
    ps.supplier_count, 
    ps.avg_supply_cost, 
    ps.total_avail_qty, 
    os.total_price, 
    os.customer_count, 
    ns.nation_supplier_count,
    ns.total_account_balance,
    CASE 
        WHEN ns.total_account_balance IS NULL THEN 'No balance'
        WHEN ns.total_account_balance < 1000 THEN 'Low balance' 
        ELSE 'High balance' 
    END AS balance_status,
    ROW_NUMBER() OVER (PARTITION BY ns.n_nationkey ORDER BY ps.avg_supply_cost DESC) AS rank_within_nation
FROM PartStats ps
JOIN OrderStats os ON ps.p_partkey = os.o_orderkey
JOIN SupplierHierarchy sh ON ps.supplier_count > sh.level
JOIN NationStats ns ON sh.s_nationkey = ns.n_nationkey
LEFT JOIN region r ON ns.n_nationkey = r.r_regionkey
WHERE (ps.total_avail_qty IS NOT NULL OR ps.total_avail_qty < 100)
ORDER BY ps.avg_supply_cost DESC, os.total_price ASC
LIMIT 50;
