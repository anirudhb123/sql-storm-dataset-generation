WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE
            WHEN p.p_type LIKE '%brass%' THEN 'Brass'
            WHEN p.p_type LIKE '%plastic%' THEN 'Plastic'
            ELSE 'Other'
        END AS type_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
), ImportantOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        s.s_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rank <= 5
        AND l.l_discount > 0.05
)
SELECT 
    fp.type_category,
    COUNT(io.o_orderkey) AS order_count,
    SUM(io.o_totalprice) AS total_revenue,
    AVG(io.o_totalprice) AS avg_order_value
FROM 
    FilteredParts fp
JOIN 
    ImportantOrders io ON fp.p_partkey = io.o_orderkey
GROUP BY 
    fp.type_category
ORDER BY 
    total_revenue DESC;
