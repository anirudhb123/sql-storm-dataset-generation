WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1995-01-01' 
      AND o.o_orderdate < DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    co.r_region_name,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(ss.total_supply_cost) AS average_supply_cost_per_supplier,
    COUNT(DISTINCT cr.c_custkey) AS total_customers
FROM RankedOrders o
JOIN CustomerRegion cr ON cr.c_custkey IN (SELECT o_custkey FROM RankedOrders WHERE order_rank = 1)
JOIN SupplierStats ss ON ss.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT l_partkey FROM lineitem WHERE l_orderkey = o.o_orderkey))
JOIN region co ON cr.region_name = co.r_name
WHERE o.o_orderstatus = 'O'
GROUP BY co.r_region_name
HAVING SUM(o.o_totalprice) > 1000000
ORDER BY total_revenue DESC;
