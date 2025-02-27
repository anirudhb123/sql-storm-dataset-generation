WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
), 
TopCustomers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.rn <= 5
    GROUP BY 
        r.r_name, n.n_name
), 
RevenueAnalysis AS (
    SELECT 
        region,
        nation,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank
    FROM 
        TopCustomers
)
SELECT 
    region, 
    nation, 
    total_revenue,
    revenue_rank,
    COUNT(DISTINCT c.c_custkey) AS customer_count
FROM 
    RevenueAnalysis ra
JOIN 
    customer c ON ra.nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = c.c_nationkey)
GROUP BY 
    region, nation, total_revenue, revenue_rank
ORDER BY 
    revenue_rank ASC, total_revenue DESC;
