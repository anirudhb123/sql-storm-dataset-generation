
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), ProductDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS order_count,
        MAX(l.l_shipdate) AS last_shipped
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), StringAggregation AS (
    SELECT 
        r.r_name AS region_name,
        LISTAGG(DISTINCT CONCAT(c.c_name, ' (', p.p_name, ')'), '; ') WITHIN GROUP (ORDER BY c.c_name) AS customer_product_details
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
        orders o ON ps.ps_partkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        EXISTS (SELECT 1 FROM RankedSuppliers rs WHERE rs.s_suppkey = s.s_suppkey AND rs.supplier_rank <= 3)
    GROUP BY 
        r.r_name
)
SELECT 
    ra.region_name, 
    ra.customer_product_details
FROM 
    StringAggregation ra
ORDER BY 
    ra.region_name;
