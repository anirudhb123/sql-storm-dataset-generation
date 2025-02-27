WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
),
PositionedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_phone,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM 
        supplier s
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_nationkey,
        c.c_phone
    FROM 
        customer c
    WHERE 
        LOWER(c.c_mktsegment) LIKE 'retail%'
),
SalesSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    ss.total_sales,
    ss.o_orderdate
FROM 
    RankedParts p
JOIN 
    PositionedSuppliers s ON s.rank_by_balance <= 5
JOIN 
    FilteredCustomers c ON c.c_nationkey = s.s_nationkey
JOIN 
    SalesSummary ss ON ss.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
WHERE 
    p.rank_by_price <= 10
ORDER BY 
    ss.total_sales DESC;
