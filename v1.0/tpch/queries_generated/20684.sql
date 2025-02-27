WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l.l_shipmode ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey, l.l_shipmode
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        p.p_type,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Account Balance'
            ELSE 'Has Account Balance'
        END AS acct_status
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000
    AND p.p_type IS NOT NULL
),
SuppliersWithSales AS (
    SELECT 
        sd.s_name,
        sd.nation_name,
        sd.acct_status,
        rs.total_sales,
        DENSE_RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM SupplierDetails sd
    JOIN RankedSales rs ON sd.s_suppkey = rs.l_orderkey
)
SELECT 
    s.s_name,
    COALESCE(SUM(sd.total_sales), 0) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN AVG(sd.total_sales) > 500 THEN 'High Roller'
        ELSE 'Standard Supplier'
    END AS supplier_type
FROM SuppliersWithSales sd
JOIN orders o ON sd.total_sales > o.o_totalprice
LEFT JOIN region r ON sd.nation_name = r.r_name
GROUP BY s.s_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_sales DESC
LIMIT 100
UNION ALL
SELECT 
    'Total' AS s_name,
    SUM(total_sales) AS total_sales,
    NULL AS order_count,
    NULL AS supplier_type
FROM SuppliersWithSales 
WHERE sales_rank = 1;
