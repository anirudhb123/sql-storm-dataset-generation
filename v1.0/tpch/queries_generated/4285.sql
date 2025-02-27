WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2024-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No comments available') AS s_comment_clean
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000 
),
SupplierOrders AS (
    SELECT 
        so.o_orderkey,
        so.o_totalprice,
        sd.s_suppkey,
        sd.s_name,
        sd.s_acctbal
    FROM 
        lineitem li
    JOIN 
        RankedOrders ro ON li.l_orderkey = ro.o_orderkey
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    so.o_orderkey,
    so.o_totalprice,
    so.s_suppkey,
    so.s_name,
    so.s_acctbal,
    CASE 
        WHEN so.o_totalprice > 5000 THEN 'High Value'
        WHEN so.o_totalprice BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS value_category,
    ROW_NUMBER() OVER (PARTITION BY so.s_suppkey ORDER BY so.o_totalprice DESC) AS order_number
FROM 
    SupplierOrders so
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = so.o_orderkey) 
WHERE 
    n.n_regionkey IS NULL 
UNION ALL
SELECT 
    NULL AS o_orderkey,
    NULL AS o_totalprice,
    sd.s_suppkey,
    sd.s_name,
    sd.s_acctbal,
    'Supplier Only' AS value_category,
    NULL AS order_number
FROM 
    SupplierDetails sd
WHERE 
    sd.s_acctbal < 1000
ORDER BY 
    s_acctbal DESC, 
    o_totalprice DESC;
