WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, NULL::integer AS parent_suppkey
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.parent_suppkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_acct_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, COUNT(DISTINCT ns.n_nationkey) AS nation_count, 
       AVG(ns.total_acct_balance) AS avg_acct_balance, 
       STRING_AGG(DISTINCT pd.p_name, ', ') AS part_names,
       ARRAY_AGG(DISTINCT od.total_revenue ORDER BY od.o_orderdate DESC) AS recent_revenues
FROM region r
LEFT JOIN NationStats ns ON ns.n_nationkey = r.r_regionkey
LEFT JOIN PartDetails pd ON pd.total_avail_qty > 1000
LEFT JOIN OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
GROUP BY r.r_name
HAVING COUNT(DISTINCT ns.n_nationkey) > 1
ORDER BY avg_acct_balance DESC;
