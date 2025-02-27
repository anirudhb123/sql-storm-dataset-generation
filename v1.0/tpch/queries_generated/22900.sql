WITH RankedParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rn
    FROM 
        part
    WHERE 
        p_retailprice IS NOT NULL
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COALESCE(s.s_acctbal, 0) AS acct_balance,
        RANK() OVER (PARTITION BY s_nationkey ORDER BY s.s_acctbal DESC) AS rn_supplier
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
ExpensiveParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (ORDER BY p.p_retailprice DESC) AS ranked
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sp.s_name, 'No Supplier') AS supplier_name,
    p.p_retailprice,
    so.total_value,
    CASE 
        WHEN so.total_value > 20000 THEN 'High Value'
        WHEN so.total_value IS NULL THEN 'No Sales'
        ELSE 'Regular Value'
    END AS order_category
FROM 
    ExpensiveParts p
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    SupplierInfo sp ON sp.s_suppkey = ps.ps_suppkey AND sp.rn_supplier = 1
LEFT JOIN 
    HighValueOrders so ON so.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderkey = so.o_orderkey)
WHERE 
    p.ranked <= 10
ORDER BY 
    p.p_retailprice DESC, 
    supplier_name;
