WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        n.n_name, n.n_regionkey
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
        o.o_orderstatus = 'F' AND 
        EXISTS (SELECT 1 FROM lineitem li WHERE li.l_orderkey = o.o_orderkey AND li.l_returnflag = 'R')
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
SalesReport AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT h.c_custkey) AS customer_count,
        COALESCE(SUM(rs.total_sales), 0) AS total_sales_by_nation,
        AVG(h.total_spent) AS avg_spent_per_customer
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        RegionalSales rs ON n.n_nationkey = rs.nation_name
    LEFT JOIN 
        HighValueCustomers h ON n.n_nationkey = h.c_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    sr.r_name AS region_name,
    sr.customer_count,
    sr.total_sales_by_nation,
    sr.avg_spent_per_customer,
    CASE 
        WHEN sr.avg_spent_per_customer IS NULL THEN 'No Customers'
        WHEN sr.total_sales_by_nation > 1000000 THEN 'High Sales Zone'
        ELSE 'Regular Sales Zone'
    END AS sales_zone
FROM 
    SalesReport sr
WHERE 
    sr.customer_count > 0
ORDER BY 
    sr.total_sales_by_nation DESC, 
    sales_zone ASC;
