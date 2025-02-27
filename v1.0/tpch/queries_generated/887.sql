WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        r.r_name
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
        total_spent > 10000
),
SupplierCompliance AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        supplied_parts < 5
)
SELECT 
    r.region_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers_count,
    COUNT(DISTINCT sc.s_suppkey) AS non_compliant_suppliers_count
FROM 
    region r
LEFT JOIN 
    RegionalSales rs ON r.r_name = rs.region_name
LEFT JOIN 
    HighValueCustomers hvc ON hvc.total_spent > 0
LEFT JOIN 
    SupplierCompliance sc ON sc.supplied_parts < 5
GROUP BY 
    r.region_name
ORDER BY 
    total_sales DESC, r.region_name;
