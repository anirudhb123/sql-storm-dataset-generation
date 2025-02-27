WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-10-31'
    GROUP BY 
        l.l_partkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_availqty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty IS NOT NULL
), 
SalesRanking AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.p_brand,
        pd.p_retailprice,
        ts.total_revenue,
        ts.order_count,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS sales_rank
    FROM 
        PartDetails pd
    JOIN 
        TotalSales ts ON pd.p_partkey = ts.l_partkey
)

SELECT 
    sr.r_name,
    sr.s_name,
    sr.s_acctbal,
    sr.rnk,
    sr_part.p_partkey,
    sr_part.p_name,
    sr_part.total_revenue,
    sr_part.order_count,
    CASE 
        WHEN sr.rnk <= 5 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_rank_category
FROM 
    RankedSuppliers sr
INNER JOIN 
    SalesRanking sr_part ON sr.s_suppkey = sr_part.p_partkey
JOIN 
    nation n ON sr.n_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    n.n_name IS NOT NULL
    AND sr.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
ORDER BY 
    sr.r_name, sr.rnk, sr_part.total_revenue DESC;
