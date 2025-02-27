WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_totalprice, o_orderdate, 1 AS order_level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT oh.o_orderkey, oh.o_totalprice, oh.o_orderdate, oh.order_level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_orderkey = oh.o_orderkey
    WHERE oh.order_level < 10
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY ps.ps_partkey
),
CustomerStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice, 
           ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size > 10
)
SELECT DISTINCT 
    o.o_orderkey,
    cs.c_custkey,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    pd.p_name,
    pd.brand_rank,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
FROM orders o
INNER JOIN lineitem li ON o.o_orderkey = li.l_orderkey
INNER JOIN CustomerStats cs ON o.o_custkey = cs.c_custkey
LEFT JOIN SupplierParts ps ON li.l_partkey = ps.ps_partkey
JOIN PartDetails pd ON li.l_partkey = pd.p_partkey
WHERE li.l_shipdate > '2023-01-01' AND li.l_returnflag = 'N'
GROUP BY o.o_orderkey, cs.c_custkey, ps.total_avail_qty, ps.avg_supply_cost, pd.p_name, pd.brand_rank
HAVING AVG(li.l_tax) > 0.05
ORDER BY revenue DESC
LIMIT 100;
