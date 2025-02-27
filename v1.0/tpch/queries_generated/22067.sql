WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        RankedSupplier rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s))
    GROUP BY 
        r.r_regionkey, r.r_name
),
AveragePrice AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost * (1 - l.l_discount)) AS avg_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        p.p_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN ap.avg_cost IS NULL THEN 'No Supply'
            ELSE 'Available'
        END AS availability
    FROM 
        part p
    LEFT JOIN 
        AveragePrice ap ON p.p_partkey = ap.p_partkey
    WHERE 
        p.p_retailprice > 1000 AND p.p_size IN (15, 20, 25)
),
FinalReport AS (
    SELECT 
        tp.r_name,
        fp.p_name,
        fp.p_retailprice,
        COUNT(DISTINCT lt.l_orderkey) AS order_count,
        SUM(CASE WHEN lt.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns
    FROM 
        TopSuppliers tp
    LEFT JOIN 
        FilteredParts fp ON tp.r_regionkey = (SELECT r.r_regionkey FROM region r INNER JOIN nation n ON r.r_regionkey = n.n_regionkey WHERE n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s) LIMIT 1)
    LEFT JOIN 
        lineitem lt ON fp.p_partkey = lt.l_partkey
    GROUP BY 
        tp.r_name, fp.p_name, fp.p_retailprice
)
SELECT 
    fr.r_name,
    fr.p_name,
    fr.p_retailprice,
    fr.order_count,
    fr.total_returns,
    CASE 
        WHEN fr.order_count > 10 THEN 'High Demand'
        WHEN fr.total_returns > 5 THEN 'High Returns'
        ELSE 'Stable'
    END AS demand_category
FROM 
    FinalReport fr
ORDER BY 
    fr.r_name, fr.p_name DESC
LIMIT 
    20 OFFSET 5;
