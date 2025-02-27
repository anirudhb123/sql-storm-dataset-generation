WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 10
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            WHEN s.s_acctbal > 10000 THEN 'High Balance'
            ELSE 'Low Balance'
        END AS balance_category
    FROM supplier s
    WHERE s.s_comment LIKE '%reliable%'
), SalesData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    COALESCE(f.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        ELSE TO_CHAR(s.total_sales, 'FM$999,999.00')
    END AS total_sales,
    r.brand_count,
    s.order_count,
    ROW_NUMBER() OVER (ORDER BY r.brand_count DESC) AS rank_in_brands,
    COALESCE(MAX(n.n_name) FILTER (WHERE n.n_regionkey IS NOT NULL), 'No Nation') AS nation_name
FROM RankedParts r
LEFT JOIN FilteredSuppliers f ON r.rnk = 1
LEFT JOIN SalesData s ON r.p_partkey = ANY(ARRAY(
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
))
LEFT JOIN nation n ON f.s_nationkey = n.n_nationkey
GROUP BY r.p_partkey, r.p_name, r.p_brand, f.s_name
HAVING COUNT(*) > 0 OR SUM(s.total_sales) IS NOT NULL
ORDER BY r.brand_count DESC, total_sales DESC;
