WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
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
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate >= DATEADD(MONTH, -12, CURRENT_DATE)
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), 

SupplierPerformance AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)

SELECT 
    r.region_name,
    s.s_name,
    COALESCE(c.c_name, 'No Customers') AS customer_name,
    hp.total_spent,
    sp.total_sales,
    sp.order_count,
    RANK() OVER (PARTITION BY r.region_name ORDER BY sp.total_sales DESC) AS supplier_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    HighValueCustomers hp ON s.s_suppkey = hp.c_custkey
LEFT JOIN 
    SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
WHERE 
    s.s_acctbal IS NOT NULL 
    AND s.s_acctbal > 1000
UNION ALL
SELECT 
    r.region_name,
    'Aggregate' AS s_name,
    COUNT(h.c_custkey) AS customer_count,
    SUM(h.total_spent) AS total_customer_spent,
    SUM(sp.total_sales) AS total_supplier_sales,
    COUNT(sp.s_suppkey) AS total_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    HighValueCustomers h ON s.s_suppkey = h.c_custkey
LEFT JOIN 
    SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
GROUP BY 
    r.region_name
ORDER BY 
    region_name, supplier_rank NULLS LAST;
