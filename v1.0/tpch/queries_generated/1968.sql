WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'Y' THEN l.l_quantity ELSE 0 END), 0) AS returned_quantity,
        COUNT(l.l_orderkey) AS total_orders
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS region_total
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
FinalResult AS (
    SELECT 
        p.p_name,
        ps.part_count,
        ps.total_supply_cost,
        RANK() OVER (ORDER BY ps.total_supply_cost DESC) AS supply_cost_rank,
        tr.region_total
    FROM 
        PartStats p
    JOIN 
        SupplierStats ps ON p.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier))
    JOIN 
        TopRegions tr ON tr.region_total > 10000
)
SELECT 
    f.p_name,
    f.part_count,
    f.total_supply_cost,
    f.supply_cost_rank,
    ro.o_orderdate,
    ro.o_totalprice
FROM 
    FinalResult f
LEFT JOIN 
    RankedOrders ro ON f.part_count > 5 AND f.total_supply_cost > 5000
ORDER BY 
    f.supply_cost_rank, ro.o_orderdate DESC
LIMIT 50;
