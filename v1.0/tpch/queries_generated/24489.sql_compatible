
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_mfgr,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
    AND 
        p.p_comment IS NOT NULL
    AND 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2 
            WHERE p2.p_type LIKE 'Type%'
        )
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2
        )
),
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    p.p_name,
    p.p_retailprice,
    s.s_name,
    c.c_custkey,
    CASE 
        WHEN c.order_count IS NULL THEN 'NO ORDERS'
        ELSE CAST(c.order_count AS VARCHAR)
    END AS order_count,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS rank
FROM 
    RankedParts p
LEFT JOIN 
    SupplierInfo s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        AND ps.ps_availqty > 0
    )
FULL JOIN 
    CustomerOrder c ON c.c_custkey = (
        SELECT o.o_custkey FROM orders o 
        WHERE o.o_orderkey = (
            SELECT MIN(o2.o_orderkey) 
            FROM orders o2 
            WHERE o2.o_orderstatus = 'O'
        )
    )
WHERE 
    p.rn <= 10
ORDER BY 
    p.p_retailprice ASC, 
    c.order_count DESC NULLS LAST;
