WITH RECURSIVE SupplierCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        sc.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierCTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        sc.level < 5
),
SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FilteredNation AS (
    SELECT 
        n.n_nationkey, 
        n.n_name
    FROM 
        nation n 
    WHERE 
        n.n_comment LIKE '%special%'
),
SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        SUM(o.o_totalprice) AS total_order_price
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(su.total_order_price, 0) AS total_order_price,
    su.total_order_price - COALESCE(sc.total_sales, 0) AS profit_loss,
    n.n_name AS nation_name,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS price_rank,
    CASE 
        WHEN su.total_order_price > 5000 THEN 'High Value'
        WHEN su.total_order_price BETWEEN 1000 AND 5000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    part p
LEFT JOIN 
    SupplierOrders su ON p.p_partkey = su.s_suppkey
LEFT JOIN 
    SalesCTE sc ON sc.o_orderkey = su.s_suppkey
INNER JOIN 
    FilteredNation n ON p.p_mfgr = n.n_nationkey
WHERE 
    p.p_size IN (SELECT p_size FROM part WHERE p_container = 'BOX')
    AND (su.total_order_price IS NOT NULL OR sc.total_sales IS NOT NULL)
ORDER BY 
    profit_loss DESC;
