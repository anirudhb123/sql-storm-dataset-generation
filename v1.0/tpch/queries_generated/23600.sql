WITH RecursiveCTE AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        1 AS level,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal * 0.9 AS s_acctbal, 
        level + 1,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        RecursiveCTE r
    JOIN supplier s ON s.s_suppkey = r.s_suppkey
    WHERE 
        level < 5
),
HighValueSuppliers AS (
    SELECT 
        r.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_bal
    FROM 
        region r
    LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        n.n_name NOT LIKE '%land%'
    GROUP BY 
        r.n_name
    HAVING 
        (SUM(s.s_acctbal) > (SELECT AVG(s_acctbal) FROM supplier)) OR
        (COUNT(s.s_suppkey) > 10)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS lineitem_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o 
    JOIN lineitem l ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    hv.nation_name,
    hv.supplier_count,
    hv.total_acct_bal,
    os.revenue,
    os.lineitem_count,
    os.last_order_date
FROM 
    HighValueSuppliers hv 
JOIN OrderSummary os ON hv.supplier_count > os.lineitem_count
FULL OUTER JOIN RecursiveCTE rec ON rec.s_suppkey = hv.supplier_count
WHERE 
    rec.rn <= 3 OR rec.level = (SELECT MAX(level) FROM RecursiveCTE)
ORDER BY 
    COALESCE(hv.total_acct_bal, 0) DESC, 
    NVL(os.revenue, 0) ASC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM supplier) % 10;
