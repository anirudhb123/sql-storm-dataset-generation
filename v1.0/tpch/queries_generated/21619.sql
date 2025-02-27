WITH RankedSales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS sales_rank
    FROM lineitem
    GROUP BY l_orderkey
),
Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(SUM(RS.total_sales), 0) AS total_order_sales,
    COUNT(DISTINCT S.s_suppkey) AS unique_suppliers,
    MAX(S.s_acctbal) AS max_supplier_acctbal,
    STRING_AGG(DISTINCT s.nation_name, ', ') WITHIN GROUP (ORDER BY s.nation_name) AS nations_supply_from,
    CASE 
        WHEN p.p_size IS NULL THEN 'Unknown Size'
        WHEN p.p_size > 20 THEN 'Large'
        ELSE 'Small or Medium'
    END AS size_category,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     WHERE c.custkey IN (SELECT o.custkey FROM orders o WHERE o.orderkey IN (SELECT l.orderkey FROM lineitem l WHERE l.partkey = p.p_partkey))) AS order_customer_count
FROM 
    part p
LEFT JOIN 
    RankedSales RS ON p.p_partkey = RS.l_orderkey
LEFT JOIN 
    partsupp PS ON p.p_partkey = PS.ps_partkey
LEFT JOIN 
    Suppliers S ON PS.ps_suppkey = S.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size
HAVING 
    (COALESCE(SUM(RS.total_sales), 0) > 1000 OR unique_suppliers > 5)
ORDER BY 
    total_order_sales DESC, max_supplier_acctbal DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
