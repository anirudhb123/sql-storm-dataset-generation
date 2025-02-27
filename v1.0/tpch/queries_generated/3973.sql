WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(COUNT(ps.ps_partkey), 0) AS part_supply_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    SUM(COALESCE(c.total_orders, 0)) AS total_orders_per_region,
    AVG(s.part_supply_count) AS avg_parts_per_supplier,
    COUNT(DISTINCT ro.o_orderkey) AS closed_orders,
    SUM(ro.o_totalprice) AS total_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders ro ON c.c_custkey = ro.o_custkey AND ro.o_orderstatus = 'F'
LEFT JOIN 
    SupplierDetails s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
        GROUP BY ps.ps_suppkey
    )
GROUP BY 
    r.r_name
HAVING 
    SUM(COALESCE(c.total_orders, 0)) > 10
ORDER BY 
    total_revenue DESC;
