WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.line_item_count,
        o.total_sales
    FROM 
        RankedOrders o
    WHERE 
        o.rank_sales <= 10
),
SupplierSales AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_size,
    COALESCE(ss.supplier_total_cost, 0) AS total_cost,
    TO_CHAR(o.o_orderdate, 'YYYY-MM-DD') AS order_date,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierSales ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    TopOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 50.00
    AND (p.p_comment LIKE '%TOY%' OR p.p_container IS NULL)
GROUP BY 
    p.p_name, 
    p.p_size, 
    ss.supplier_total_cost, 
    o.o_orderdate
ORDER BY 
    total_cost DESC, 
    order_count DESC;
