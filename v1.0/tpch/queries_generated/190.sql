WITH TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
OrdersWithSupplier AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        l.l_partkey, 
        l.l_quantity, 
        ts.total_supply_cost
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
        AND l.l_quantity > 0
)
SELECT 
    ows.o_orderkey,
    COUNT(ows.l_partkey) AS total_parts,
    SUM(ows.l_quantity) AS total_quantity,
    AVG(ows.total_supply_cost) AS avg_supply_cost
FROM 
    OrdersWithSupplier ows
GROUP BY 
    ows.o_orderkey
HAVING 
    SUM(ows.l_quantity) > 100
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;

SELECT 
    p.p_name, 
    p.p_brand, 
    AVG(l.l_discount) AS avg_discount
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_returnflag IS NULL
GROUP BY 
    p.p_name, p.p_brand
HAVING 
    AVG(l.l_discount) > 0.1
UNION ALL
SELECT 
    'Total Discounts' AS p_name, 
    NULL AS p_brand, 
    SUM(l.l_discount) AS avg_discount
FROM 
    lineitem l
WHERE 
    l.l_returnflag IS NULL;
