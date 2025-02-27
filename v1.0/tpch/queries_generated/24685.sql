WITH RankedLineItems AS (
    SELECT 
        l.orderkey, 
        l.partkey, 
        l.suppkey, 
        l.linenumber, 
        l.quantity, 
        l.extendedprice, 
        l.discount, 
        l.tax, 
        l.returnflag, 
        l.linestatus, 
        l.shipdate, 
        l.commitdate, 
        l.receiptdate, 
        l.shipinstruct, 
        l.shipmode, 
        l.comment,
        ROW_NUMBER() OVER (PARTITION BY l.orderkey ORDER BY l.extendedprice DESC) AS rn
    FROM 
        lineitem l
    WHERE 
        l.orderkey IN (SELECT o.orderkey FROM orders o WHERE o.orderdate < CURRENT_DATE - INTERVAL '30 days' AND o.orderstatus = 'O')
),
MaxExtendedPrice AS (
    SELECT 
        l.partkey, 
        MAX(l.extendedprice) AS max_price
    FROM 
        RankedLineItems l
    GROUP BY 
        l.partkey
),
SuppliersWithHighSupplyCost AS (
    SELECT 
        s.suppkey, 
        s.name, 
        s.acctbal 
    FROM 
        supplier s
    WHERE 
        s.acctbal IS NOT NULL 
        AND s.acctbal > (SELECT AVG(s2.acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL)
)
SELECT 
    p.p_name, 
    (p.p_retailprice * COALESCE(m.max_price, 0)) AS calculated_value, 
    s.s_name AS supplier_name, 
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'No Account Balance'
        WHEN s.s_acctbal > 1000 THEN 'High Balance'
        ELSE 'Low Balance' 
    END AS balance_category
FROM 
    part p
LEFT JOIN 
    MaxExtendedPrice m ON p.p_partkey = m.partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    SuppliersWithHighSupplyCost s ON ps.ps_suppkey = s.suppkey
WHERE 
    (p.p_size < 20 OR p.p_type LIKE '%widget%')
    AND (s.s_name LIKE 'A%' OR s.s_name IS NULL)
    AND EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_discount > 0.05)
ORDER BY 
    calculated_value DESC, 
    p.p_name;
