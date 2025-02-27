WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerNation AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, 
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'No Balance'
               ELSE 'Balance Available'
           END AS balance_status
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT o.order_rank, coalesce(cp.nation_name, 'Unknown') AS customer_nation,
       SUM(tli.total_sales) AS total_sales,
       SUM(sp.total_availqty) AS total_availability,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(CASE 
               WHEN sp.avg_supplycost > 100 THEN sp.avg_supplycost 
               ELSE 0 
           END) AS high_cost_parts
FROM RankedOrders o
LEFT OUTER JOIN CustomerNation cp ON o.o_orderkey = cp.c_custkey
LEFT JOIN TotalLineItems tli ON o.o_orderkey = tli.l_orderkey
LEFT JOIN SupplierParts sp ON sp.ps_partkey IN (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_supplycost > 50
)
GROUP BY o.order_rank, cp.nation_name
HAVING SUM(tli.total_sales) > 1000
ORDER BY o.order_rank DESC;
