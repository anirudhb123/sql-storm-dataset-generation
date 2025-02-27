WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
LineItemSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(lo.total_sales) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        LineItemSales lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(lo.total_sales) > 10000
)
SELECT 
    r.r_name AS region_name,
    SUM(total_supply_cost) AS total_supply_costs,
    COUNT(DISTINCT tc.c_custkey) AS number_of_top_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
LEFT JOIN 
    TopCustomers tc ON s.s_nationkey = tc.c_nationkey
WHERE 
    n.n_comment NOT LIKE '%dummy%'
GROUP BY 
    r.r_name
HAVING 
    SUM(total_supply_cost) IS NOT NULL
ORDER BY 
    total_supply_costs DESC;
