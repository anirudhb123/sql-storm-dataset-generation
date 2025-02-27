WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_totalprice > 10000 THEN 'High'
            WHEN o.o_totalprice BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS price_category
    FROM 
        orders o
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_net_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_totalprice,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    th.price_category,
    tl.total_net_price,
    CASE 
        WHEN th.price_category = 'High' AND tl.total_net_price > o.o_totalprice THEN 'Discrepancy'
        ELSE 'Normal'
    END AS order_status
FROM 
    HighValueOrders th
LEFT JOIN 
    RankedSuppliers r ON r.rn = 1 AND th.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_quantity > 10)
JOIN 
    TotalLineItems tl ON tl.l_orderkey = th.o_orderkey 
FULL OUTER JOIN 
    orders o ON th.o_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate > DATEADD(month, -6, CURRENT_DATE)
    AND (r.s_acctbal IS NULL OR r.s_acctbal > 5000)
ORDER BY 
    o.o_orderkey DESC, 
    total_net_price DESC NULLS LAST;
