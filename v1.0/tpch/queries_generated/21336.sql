WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 0
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS total_parts,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Account Balance' 
            WHEN s.s_acctbal < 5000 THEN 'Low Balance' 
            ELSE 'Sufficient Balance' 
        END AS balance_status
    FROM 
        supplier s
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        AVG(l.l_tax) AS avg_tax,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    ci.c_name,
    si.total_parts,
    si.balance_status,
    rp.p_name,
    rp.p_retailprice,
    cl.total_spent,
    cl.order_count,
    lis.total_line_price,
    lis.avg_tax,
    COALESCE(lis.last_ship_date, '9999-12-31') AS last_ship_or_null
FROM 
    SupplierInfo si
JOIN 
    RankedParts rp ON si.total_parts > 2 AND rp.rn <= 5
JOIN 
    CustomerOrders cl ON cl.total_spent > 10000
LEFT JOIN 
    LineItemSummary lis ON lis.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE 
    si.balance_status IS NOT NULL
ORDER BY 
    ci.c_name,
    rp.p_retailprice DESC
LIMIT 100;

