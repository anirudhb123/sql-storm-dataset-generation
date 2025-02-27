WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'  -- Open orders
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
    WHERE o.o_orderstatus = 'O' AND oh.level < 5  -- Limit hierarchy depth
),
RecentLineItems AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    WHERE l_shipdate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY l_orderkey
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available, MIN(ps.ps_supplycost) AS min_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)  -- Customers with above-average account balance
)
SELECT 
    oh.o_orderkey,
    SUM(rl.total_revenue) AS order_revenue,
    COUNT(DISTINCT sp.ps_suppkey) AS supplier_count,
    MIN(sp.min_supply_cost) AS cheapest_supplier_cost,
    cd.c_name,
    cd.nation_name
FROM OrderHierarchy oh
LEFT JOIN RecentLineItems rl ON oh.o_orderkey = rl.l_orderkey
LEFT JOIN SupplierPartDetails sp ON sp.ps_partkey IN 
    (SELECT p.p_partkey 
     FROM part p 
     JOIN lineitem l ON p.p_partkey = l.l_partkey 
     WHERE l.l_orderkey = oh.o_orderkey)
LEFT JOIN CustomerDetails cd ON oh.o_custkey = cd.c_custkey
GROUP BY oh.o_orderkey, cd.c_name, cd.nation_name
HAVING COUNT(DISTINCT sp.ps_suppkey) > 3  -- More than 3 suppliers involved
ORDER BY order_revenue DESC, cd.nation_name ASC;
