WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS bal_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS acct_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_linenumber) AS line_count,
        o.o_orderdate,
        COALESCE(MAX(l.l_shipdate), '1990-01-01') AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
        AND l.l_shipinstruct = 'DELIVER IN PERSON'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    P.p_name,
    C.c_name AS customer_name,
    R.nation,
    S.s_name AS supplier_name,
    OD.total_sales,
    CASE 
        WHEN OD.total_sales > 50000 THEN 'High Value'
        WHEN OD.total_sales BETWEEN 10000 AND 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category,
    DENSE_RANK() OVER (PARTITION BY R.nation ORDER BY OD.total_sales DESC) AS sales_rank
FROM 
    part P
LEFT JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
LEFT JOIN 
    RankedSuppliers S ON PS.ps_suppkey = S.s_suppkey
LEFT JOIN 
    CustomerInfo C ON S.s_nationkey = C.c_nationkey
JOIN 
    OrderDetails OD ON OD.o_orderkey = S.s_suppkey
JOIN 
    nation R ON S.s_nationkey = R.n_nationkey
WHERE 
    P.p_retailprice IS NOT NULL
    AND (P.p_comment LIKE '%fragile%' OR S.s_comment IS NULL)
    AND OD.last_ship_date > (CURRENT_DATE - INTERVAL '1 year')
ORDER BY 
    R.nation,
    OD.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
