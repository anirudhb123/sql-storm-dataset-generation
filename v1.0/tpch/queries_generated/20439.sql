WITH RankedSuppliers AS (
    SELECT 
        ps.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey, s.s_name, ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name, 
        p.p_brand,
        CASE 
            WHEN p.p_size IS NOT NULL THEN p.p_size
            ELSE (SELECT MAX(p2.p_size) FROM part p2 WHERE p2.p_brand = p.p_brand)
        END AS computed_size
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 10.00 AND 100.00 OR 
        (p.p_container IS NULL AND p.p_comment LIKE '%fragile%')
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
),
SuspiciousTransactions AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
),
FinalReport AS (
    SELECT 
        fp.p_partkey,
        COUNT(DISTINCT cs.c_custkey) AS unique_customers,
        COALESCE(SUM(st.net_price), 0) AS suspicious_total
    FROM 
        FilteredParts fp
    LEFT JOIN 
        CustomerOrders cs ON fp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = fp.p_partkey))
    LEFT JOIN 
        SuspiciousTransactions st ON cs.order_count > 10
    GROUP BY 
        fp.p_partkey
)
SELECT 
    fr.p_partkey,
    fr.unique_customers,
    fr.suspicious_total,
    CASE
        WHEN fr.suspicious_total > 0 THEN 'Check Transactions'
        ELSE 'All Clear'
    END AS transaction_status
FROM 
    FinalReport fr
WHERE 
    fr.unique_customers >= ALL (SELECT unique_customers FROM FinalReport) OR fr.suspicious_total IS NULL
ORDER BY 
    fr.suspicious_total DESC, fr.unique_customers ASC;
