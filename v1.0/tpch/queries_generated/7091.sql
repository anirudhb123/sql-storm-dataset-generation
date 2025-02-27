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
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_price
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
)

SELECT 
    rs.nation_name,
    c.c_name,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    AVG(co.total_line_item_price) AS avg_order_value,
    MAX(rs.total_supply_cost) AS max_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    CustomerOrders co ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            JOIN orders o ON l.l_orderkey = o.o_orderkey 
            WHERE o.o_orderstatus = 'O'
        )
    )
JOIN 
    customer c ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
        WHERE s.s_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = rs.nation_name
        )
    )
GROUP BY 
    rs.nation_name, c.c_name
ORDER BY 
    rs.nation_name, avg_order_value DESC;
