WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSupplierPerNation AS (
    SELECT 
        nation_name,
        s_name,
        total_supply_cost
    FROM 
        RankedSuppliers
    WHERE 
        rank = 1
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    t.nation_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    SUM(ro.l_extendedprice * (1 - ro.l_discount)) AS total_revenue,
    SUM(ro.l_tax) AS total_tax,
    s.s_name
FROM 
    TopSupplierPerNation t
JOIN 
    RecentOrders ro ON ro.l_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (
            SELECT s_suppkey 
            FROM supplier 
            WHERE s_name = t.s_name
        )
    )
GROUP BY 
    t.nation_name, s.s_name
ORDER BY 
    total_revenue DESC;
