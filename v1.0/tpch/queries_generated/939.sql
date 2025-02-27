WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),

SupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment,
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS sup_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        p.p_retailprice > 100.00
),

OrderLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),

PopularItems AS (
    SELECT 
        li.l_partkey, 
        COUNT(*) AS total_sales
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        li.l_partkey
    HAVING 
        COUNT(*) > 50
)

SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    oi.total_price,
    CASE 
        WHEN oi.total_price > 1000 THEN 'High'
        WHEN oi.total_price BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS price_category,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    STRING_AGG(s.s_name, ', ') AS supplier_names
FROM 
    RankedOrders o
LEFT JOIN 
    OrderLineItems oi ON o.o_orderkey = oi.l_orderkey
LEFT JOIN 
    SupplierDetails ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_partkey IN (SELECT li.l_partkey FROM lineitem li WHERE li.l_orderkey = o.o_orderkey))
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    o.price_rank = 1
GROUP BY 
    o.o_orderkey, o.o_orderdate, oi.total_price
ORDER BY 
    o.o_orderdate DESC, total_price DESC;
