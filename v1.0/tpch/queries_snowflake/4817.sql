
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.nation_name,
        ss.total_available,
        ss.avg_supply_cost,
        ss.part_count,
        RANK() OVER (PARTITION BY ss.nation_name ORDER BY ss.avg_supply_cost DESC) AS rank_within_nation
    FROM SupplierStats ss
    WHERE ss.total_available > 10000 AND ss.avg_supply_cost IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    hs.s_name, 
    hs.nation_name,
    hs.total_available,
    hs.avg_supply_cost,
    co.c_name,
    co.order_count,
    co.total_spent
FROM HighValueSuppliers hs
FULL OUTER JOIN CustomerOrders co ON hs.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey LIMIT 1))
WHERE hs.rank_within_nation <= 5 OR co.order_count > 0
ORDER BY hs.nation_name, hs.avg_supply_cost DESC, co.total_spent DESC;
