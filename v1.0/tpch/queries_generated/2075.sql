WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
BestSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count 
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank = 1
    GROUP BY 
        r.r_name, n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    b.region_name,
    b.nation_name,
    COUNT(DISTINCT h.o_orderkey) AS high_value_orders,
    AVG(h.order_value) AS avg_order_value
FROM 
    BestSuppliers b
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey IN (
        SELECT l.o_orderkey
        FROM lineitem l
        JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
        WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    )
GROUP BY 
    b.region_name, b.nation_name
ORDER BY 
    b.region_name, b.nation_name;
