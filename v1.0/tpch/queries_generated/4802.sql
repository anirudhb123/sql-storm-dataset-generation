WITH RankedSales AS (
    SELECT 
        ps.partkey,
        ps.suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.partkey, ps.suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > 10000
)

SELECT 
    p.p_name,
    r.r_name,
    s.s_name,
    COALESCE(ranked.total_sales, 0) AS total_sales,
    high_value.total_spent AS customer_spending
FROM 
    part p
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)))
LEFT JOIN 
    RankedSales ranked ON p.p_partkey = ranked.partkey AND ranked.sales_rank = 1
LEFT JOIN 
    HighValueCustomers high_value ON high_value.total_orders > 10
WHERE 
    p.p_retailprice > 0
ORDER BY 
    total_sales DESC, customer_spending ASC
LIMIT 100;
