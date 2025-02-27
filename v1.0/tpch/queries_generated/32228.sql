WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
        o.o_orderdate, 
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierProduct AS (
    SELECT 
        s.s_suppkey, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        SupplierProduct ps
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 10000
)
SELECT 
    n.n_name AS supplier_nation,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS finalized_sales,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    SupplierProduct sp ON l.l_suppkey = sp.s_suppkey
JOIN 
    nation n ON sp.s_nationkey = n.n_nationkey
LEFT JOIN 
    HighValueSuppliers hvs ON sp.s_suppkey = hvs.s_suppkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (hvs.total_avail_qty IS NOT NULL OR l.l_returnflag = 'N')
GROUP BY 
    n.n_name
HAVING 
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) > 50000
ORDER BY 
    finalized_sales DESC;
