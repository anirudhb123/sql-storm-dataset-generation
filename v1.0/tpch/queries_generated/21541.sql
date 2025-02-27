WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'NULL_RETAILPRICE'
            ELSE 'VALID_RETAILPRICE'
        END AS price_status
    FROM part p
), SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY ps.ps_partkey, s.s_suppkey
), SalesWithRank AS (
    SELECT 
        s.ps_partkey,
        s.s_suppkey,
        s.total_sales,
        s.order_count,
        RANK() OVER (PARTITION BY s.ps_partkey ORDER BY s.total_sales DESC) AS sales_rank
    FROM SupplierSales s
), PreferredSuppliers AS (
    SELECT 
        sr.s_suppkey,
        SUM(sr.total_sales) AS total_sales_sum
    FROM SalesWithRank sr
    WHERE sr.sales_rank = 1
    GROUP BY sr.s_suppkey
    HAVING SUM(sr.total_sales) > (SELECT AVG(total_sales) FROM SupplierSales)
), NationwideResults AS (
    SELECT 
        n.n_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        MAX(p.price_status) AS max_price_status
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
    LEFT JOIN RankedParts p ON ps.ps_partkey = p.p_partkey
    WHERE n.n_name NOT IN (SELECT DISTINCT n_name FROM region WHERE r_name LIKE '%east%')
    GROUP BY n.n_name
)
SELECT 
    nr.n_name, 
    nr.total_available,
    nr.customer_count,
    COALESCE(ps.total_sales_sum, 0) AS preferred_supplier_sales
FROM NationwideResults nr
LEFT JOIN PreferredSuppliers ps ON nr.customer_count > 0
ORDER BY nr.customer_count DESC, nr.total_available DESC;
