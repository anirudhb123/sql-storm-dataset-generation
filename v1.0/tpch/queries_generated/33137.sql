WITH RECURSIVE RegionSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
), RankedSales AS (
    SELECT 
        r.r_name,
        r.total_sales,
        RANK() OVER (ORDER BY r.total_sales DESC) AS sales_rank
    FROM 
        RegionSales r
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
), CustomerRank AS (
    SELECT 
        cvc.c_custkey,
        cvc.c_name,
        cvc.total_spent,
        RANK() OVER (ORDER BY cvc.total_spent DESC) AS customer_rank
    FROM 
        HighValueCustomers cvc
), SupplierPartCounts AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    rr.r_name AS region_name,
    rr.total_sales AS region_total_sales,
    cr.c_name AS customer_name,
    cr.total_spent AS customer_total_spent,
    sp.part_count AS supplier_parts_available,
    COALESCE(rr.total_sales / NULLIF(sp.part_count, 0), 0) AS sales_per_part
FROM 
    RankedSales rr
LEFT JOIN 
    CustomerRank cr ON rr.sales_rank = cr.customer_rank
LEFT JOIN 
    SupplierPartCounts sp ON rr.r_regionkey = sp.s_suppkey
WHERE 
    rr.total_sales > 10000
ORDER BY 
    rr.region_total_sales DESC, 
    cr.total_spent DESC;
