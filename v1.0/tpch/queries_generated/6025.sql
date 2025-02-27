WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
), 
TotalOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority
)
SELECT 
    rs.s_name,
    rs.total_supply_cost,
    COUNT(DISTINCT to.o_orderkey) AS order_count,
    SUM(to.net_revenue) AS total_revenue
FROM 
    RankedSuppliers rs
LEFT JOIN 
    TotalOrders to ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
        )
    )
WHERE 
    rs.rn <= 5
GROUP BY 
    rs.s_name, rs.total_supply_cost
ORDER BY 
    total_revenue DESC, total_supply_cost DESC;
