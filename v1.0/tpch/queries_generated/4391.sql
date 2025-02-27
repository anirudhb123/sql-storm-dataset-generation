WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name,
    cr.nation_name,
    COUNT(DISTINCT cr.c_custkey) AS customer_count,
    SUM(spd.ps_availqty) AS total_available_quantity,
    SUM(spd.ps_supplycost) AS total_supply_cost,
    AVG(oo.o_totalprice) AS avg_order_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM CustomerRegion cr
LEFT JOIN SupplierPartDetails spd ON cr.nation_name = spd.s_name
LEFT JOIN RankedOrders oo ON cr.c_custkey = oo.o_orderkey
WHERE spd.ps_availqty > 0
AND cr.region_name IS NOT NULL
GROUP BY cr.region_name, cr.nation_name
HAVING COUNT(DISTINCT cr.c_custkey) > 5
ORDER BY customer_count DESC, total_supply_cost DESC
LIMIT 100;
