WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
), DetailedOrderInfo AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.o_orderkey,
        co.o_orderdate,
        co.o_totalprice,
        COUNT(li.l_orderkey) AS line_item_count,
        SUM(li.l_extendedprice) AS total_line_item_price
    FROM 
        CustomerOrders co
    JOIN 
        lineitem li ON co.o_orderkey = li.l_orderkey
    GROUP BY 
        co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice
)
SELECT 
    rs.nation_name,
    rs.s_name,
    doi.c_custkey,
    doi.c_name,
    doi.o_orderkey,
    doi.o_orderdate,
    doi.o_totalprice,
    doi.line_item_count,
    doi.total_line_item_price,
    rs.total_supply_value
FROM 
    RankedSuppliers rs
JOIN 
    DetailedOrderInfo doi ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_size > 20
        )
    )
WHERE 
    rs.supplier_rank <= 5
ORDER BY 
    rs.nation_name, rs.total_supply_value DESC, doi.o_orderdate DESC;
