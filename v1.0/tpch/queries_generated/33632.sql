WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
ActiveRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT c.c_name, COALESCE(cs.total_spent, 0) AS total_spent,
       ps.p_partkey, ps.supplier_count,
       o.o_orderkey, r.order_rank,
       ar.r_name AS region, ar.nation_count
FROM CustomerSpending cs
FULL OUTER JOIN PartSupplier ps ON cs.c_custkey = ps.p_partkey
JOIN RankedOrders r ON r.o_orderkey = ps.p_partkey 
LEFT JOIN ActiveRegions ar ON ar.r_regionkey = cs.c_custkey
WHERE (cs.total_spent > 500 OR ps.supplier_count > 3) 
AND (r.order_rank IS NULL OR r.order_rank < 10)
ORDER BY cs.total_spent DESC, ps.supplier_count ASC;
