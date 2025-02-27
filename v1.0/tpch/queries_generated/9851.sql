WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighCostSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_within_nation = 1
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    r.s_name AS supplier_name,
    r.nation_name,
    r.total_supply_cost,
    o.o_orderkey,
    o.total_revenue
FROM 
    HighCostSuppliers r
JOIN 
    RecentOrders o ON r.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey
        )
    )
ORDER BY 
    r.total_supply_cost DESC, 
    o.total_revenue DESC
LIMIT 10;
