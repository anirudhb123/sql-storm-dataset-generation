WITH SupplierTotals AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        st.s_suppkey,
        st.s_name
    FROM 
        SupplierTotals st
    WHERE 
        st.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierTotals)
)
SELECT 
    c.c_name AS customer_name,
    SUBSTRING(c.c_address FROM 1 FOR 15) AS short_address,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT st.s_name, ', ') AS suppliers
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    HighValueSuppliers st ON l.l_suppkey = st.s_suppkey
JOIN 
    supplier s ON st.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, c.c_address, r.r_name
ORDER BY 
    c.c_name;