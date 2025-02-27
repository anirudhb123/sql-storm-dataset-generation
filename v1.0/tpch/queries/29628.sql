WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        ro.c_name AS customer_name,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rn <= 3 
)
SELECT 
    region_name,
    nation_name,
    STRING_AGG(CONCAT(customer_name, ': ', o_totalprice), '; ') AS top_customers
FROM 
    TopCustomers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;