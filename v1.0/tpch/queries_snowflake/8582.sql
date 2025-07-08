WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    rs.region_name,
    rs.total_suppliers,
    rs.total_supply_value,
    co.order_count,
    co.total_spent,
    lis.total_revenue,
    lis.avg_quantity
FROM 
    RegionStats rs
JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY RANDOM() LIMIT 1)
JOIN 
    LineItemStats lis ON lis.l_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY RANDOM() LIMIT 1)
ORDER BY 
    rs.total_supply_value DESC
LIMIT 10;
