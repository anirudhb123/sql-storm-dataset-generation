WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal > sh.s_acctbal AND sh.level < 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
HighValueSales AS (
    SELECT 
        od.o_orderkey,
        od.sales
    FROM 
        OrderDetails od
    WHERE 
        od.sales > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    ph.s_name AS supplier_name,
    H.sales,
    ph.level AS hierarchy_level,
    CASE 
        WHEN H.s_acctbal IS NULL THEN 'N/A'
        ELSE CAST(H.s_acctbal AS VARCHAR)
    END AS account_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier ph ON ps.ps_suppkey = ph.s_suppkey
LEFT JOIN 
    HighValueSales H ON H.o_orderkey = ps.ps_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = H.o_orderkey
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
    AND ph.s_name IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_nationkey = ph.s_nationkey
        AND c.c_acctbal > 0
    )
GROUP BY 
    p.p_partkey, p.p_name, ph.s_name, H.sales, ph.level, H.s_acctbal
ORDER BY 
    p.p_partkey, order_count DESC;
