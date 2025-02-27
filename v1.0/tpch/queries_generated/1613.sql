WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartMetrics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        AVG(l.l_discount) AS avg_discount,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    r.r_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(pm.avg_discount, 0) AS avg_discount,
    COUNT(DISTINCT ro.o_orderkey) AS completed_orders
FROM 
    region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplierstats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN partmetrics pm ON pm.p_brand = ss.s_name
LEFT JOIN RankedOrders ro ON ro.o_orderstatus = 'F' AND ro.rn <= 10
WHERE 
    r.r_name LIKE '%North%' OR r.r_name IS NULL
GROUP BY 
    r.r_name, ss.total_supply_cost, pm.avg_discount
ORDER BY 
    total_supply_cost DESC NULLS LAST;
