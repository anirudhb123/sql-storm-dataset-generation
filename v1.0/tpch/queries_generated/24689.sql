WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rank_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CASE 
            WHEN s.s_acctbal > 1000 THEN 'High'
            WHEN s.s_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS account_balance_category
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
)
SELECT 
    r.r_name AS "Region",
    np.n_name AS "Nation",
    COUNT(DISTINCT pc.p_partkey) AS "Distinct Parts Count",
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS "Total Sales",
    AVG(o.o_totalprice) AS "Average Order Value",
    MAX(rp.rank_retailprice) AS "Max Retail Price Rank"
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation np ON s.s_nationkey = np.n_nationkey
JOIN 
    region r ON np.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON rp.p_partkey = l.l_partkey
LEFT JOIN 
    RecentOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = ro.o_custkey
WHERE 
    rp.rank_retailprice <= 5 
    AND (hvc.total_spent IS NOT NULL OR ro.line_count > 0)
    AND s.s_name NOT LIKE '%test%'
GROUP BY 
    r.r_name, np.n_name
HAVING 
    COUNT(DISTINCT rp.p_partkey) > 10
ORDER BY 
    "Region", "Nation";
