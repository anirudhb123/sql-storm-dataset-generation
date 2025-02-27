WITH RankedSuppliers AS (
    SELECT 
        s_name,
        n_name AS nation_name,
        SUM(ps_supplycost * ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        s.nation_name,
        t.s_name,
        t.total_supply_value
    FROM 
        RankedSuppliers t
    JOIN 
        nation n ON t.nation_name = n.n_name
    WHERE 
        t.rank <= 3
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUM(l.l_extendedprice - l.l_discount) AS total_sales_value,
    ts.nation_name
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    TopSuppliers ts ON o.o_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_name LIKE CONCAT('%', ts.s_name, '%')
        LIMIT 1
    )
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
WHERE 
    o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
GROUP BY 
    p.p_name, ts.nation_name
ORDER BY 
    total_sales_value DESC
LIMIT 10;
