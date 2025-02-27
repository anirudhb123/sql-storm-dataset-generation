WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
OrderAmounts AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
TotalAmountByRegion AS (
    SELECT 
        n.n_regionkey,
        SUM(oa.total_amount) AS region_total
    FROM 
        OrderAmounts oa
    JOIN 
        customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = oa.o_orderkey)
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    COALESCE(sa.total_available, 0) AS available_quantity,
    COALESCE(tr.region_total, 0) AS total_region_sales,
    CONCAT('Supplier: ', rs.s_name, ' | Price: ', CAST(p.p_retailprice AS varchar), ' | Comment: ', p.p_comment) AS description
FROM 
    part p
LEFT JOIN 
    SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1
LEFT JOIN 
    TotalAmountByRegion tr ON tr.n_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey))
WHERE 
    (p.p_size > 20 AND p.p_retailprice < 100) 
    OR (p.p_type LIKE '%metal%' AND p.p_comment IS NOT NULL)
ORDER BY 
    available_quantity DESC, total_region_sales DESC;
