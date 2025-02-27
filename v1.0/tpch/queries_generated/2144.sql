WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    ns.brands,
    CASE WHEN cs.total_spent IS NULL THEN 0 ELSE cs.total_spent END AS total_spent_by_customer,
    COALESCE(ROUND(RS.total_sales, 2), 0) AS total_sales_per_part,
    RANK() OVER (ORDER BY COALESCE(total_sales, 0) DESC) AS sales_rank
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    (SELECT 
         n.n_nationkey,
         STRING_AGG(DISTINCT p.p_brand, ', ') AS brands
     FROM 
         supplier s
     JOIN 
         partsupp ps ON s.s_suppkey = ps.ps_suppkey
     JOIN 
         part p ON ps.ps_partkey = p.p_partkey
     GROUP BY 
         n.n_nationkey) ns ON ns.n_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders cs ON cs.order_count > 10
LEFT JOIN 
    RankedSales RS ON RS.p_partkey = ps.ps_partkey
WHERE 
    cs.total_spent IS NULL OR cs.total_spent > 1000
ORDER BY 
    total_sales_per_part DESC, total_spent_by_customer ASC;
