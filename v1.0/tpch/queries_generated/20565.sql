WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown'
            WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
            WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(s.s_acctbal, 0) AS account_balance,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM 
        supplier s
    WHERE 
        s.s_comment NOT LIKE '%obsolete%'
),
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
EnhancedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        COALESCE(LAG(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber), 0) AS prev_extended_price,
        l.l_discount,
        l.l_tax,
        l.l_shipdate,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        lineitem l
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_retailprice,
    si.s_name AS supplier_name,
    si.account_balance AS supplier_balance,
    co.c_name AS customer_name,
    co.o_orderkey,
    co.o_totalprice,
    co.o_orderdate,
    eli.return_status,
    (eli.l_discount * 100) AS discount_percentage,
    CASE 
        WHEN eli.prev_extended_price IS NOT NULL AND eli.l_extendedprice > eli.prev_extended_price THEN 'Price Increased'
        ELSE 'Price Unchanged or Decreased'
    END AS price_change_status
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey AND si.acct_rank <= 5
JOIN 
    EnhancedLineItems eli ON eli.l_partkey = rp.p_partkey
JOIN 
    CustomerOrder co ON co.o_orderkey = eli.l_orderkey
WHERE 
    rp.price_rank <= 10
    AND co.order_rank = 1 
    AND (si.account_balance > 1000 OR si.s_name LIKE 'A%')
ORDER BY 
    rp.p_retailprice DESC, co.o_totalprice ASC;
