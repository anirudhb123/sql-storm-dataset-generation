WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
DenseRankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
OrderDetails AS (
    SELECT lo.l_orderkey, lo.l_quantity, lo.l_extendedprice, lo.l_discount, 
           lo.l_returnflag, lo.l_shipdate
    FROM lineitem lo
    LEFT JOIN DenseRankedOrders dro ON lo.l_orderkey = dro.o_orderkey
    WHERE dro.price_rank <= 10
),
NationalInfo AS (
    SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
)
SELECT p.p_name, p.p_mfgr, p.p_brand, 
       COALESCE(DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY total_supply_cost DESC), 0) AS rank_by_cost,
       AVG(od.l_extendedprice * (1 - od.l_discount)) AS avg_price_after_discount,
       COUNT(DISTINCT od.l_orderkey) AS distinct_order_count
FROM part p
JOIN OrderDetails od ON p.p_partkey = od.l_partkey
JOIN NationalInfo n ON n.total_supply_cost > 1000
GROUP BY p.p_name, p.p_mfgr, p.p_brand, n.n_name
HAVING COUNT(od.l_orderkey) > 5
ORDER BY rank_by_cost, avg_price_after_discount DESC
LIMIT 50;
