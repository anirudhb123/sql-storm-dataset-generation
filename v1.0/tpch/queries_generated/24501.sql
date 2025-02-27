WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
), SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_nationkey
), CustomerStats AS (
    SELECT 
        c.c_nationkey, 
        AVG(c.c_acctbal) AS avg_acctbal, 
        MAX(c.c_acctbal) AS max_acctbal,
        MIN(CASE WHEN c.c_acctbal < 0 THEN c.c_acctbal ELSE NULL END) AS min_negative_acctbal
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
), OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name, 
    COALESCE(cs.avg_acctbal, 0) AS avg_acctbal,
    COALESCE(su.total_supply_cost, 0) AS total_supply_cost,
    (SELECT COUNT(*) FROM RankedParts rp WHERE rp.rn = 1) AS top_parts_count,
    CASE 
        WHEN cs.min_negative_acctbal IS NOT NULL THEN 'Has Negative Balance' 
        ELSE 'All Non-negative' 
    END AS account_status
FROM 
    region r
LEFT JOIN 
    SupplierSummary su ON r.r_regionkey = su.s_nationkey
LEFT JOIN 
    CustomerStats cs ON cs.c_nationkey = su.s_nationkey
WHERE 
    r.r_name LIKE 'N%'
ORDER BY 
    r.r_name DESC
LIMIT 5
UNION ALL
SELECT 
    DISTINCT 'Total Orders' AS r_name,
    SUM(cs.avg_acctbal) AS avg_acctbal,
    SUM(su.total_supply_cost) AS total_supply_cost,
    (SELECT COUNT(*) FROM RankedParts) AS top_parts_count,
    (SELECT
        CASE 
            WHEN MIN(cs.min_negative_acctbal) IS NOT NULL THEN 'Has Negative Balance' 
            ELSE 'All Non-negative' 
        END
    FROM CustomerStats cs) AS account_status
FROM 
    SupplierSummary su
JOIN 
    CustomerStats cs ON su.s_nationkey = cs.c_nationkey
HAVING
    SUM(cs.avg_acctbal) > 0;
