WITH RECURSIVE RecentOrders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus
    FROM orders
    WHERE o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus
    FROM orders o
    JOIN RecentOrders ro ON o.o_orderkey = ro.o_orderkey - 1
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
CustomerAnalysis AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 0
),
PriceRankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
FinalAnalysis AS (
    SELECT 
        ra.o_orderkey,
        ra.o_orderstatus,
        ca.order_count,
        ca.avg_order_value,
        tp.total_supply_cost,
        pp.p_name,
        pp.p_retailprice,
        pp.price_rank
    FROM RecentOrders ra
    LEFT JOIN CustomerAnalysis ca ON ra.o_custkey = ca.c_custkey
    LEFT JOIN TopSuppliers tp ON tp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%' LIMIT 1))
    LEFT JOIN PriceRankedParts pp ON pp.price_rank <= 5
)
SELECT DISTINCT 
    f.o_orderkey,
    f.o_orderstatus,
    f.order_count,
    f.avg_order_value,
    f.total_supply_cost,
    f.p_name,
    f.p_retailprice
FROM FinalAnalysis f
WHERE f.total_supply_cost IS NOT NULL
ORDER BY f.order_count DESC, f.avg_order_value DESC;