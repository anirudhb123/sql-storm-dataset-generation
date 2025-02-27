WITH TotalSales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '2022-01-01' AND l_shipdate < DATE '2023-01-01'
    GROUP BY 
        l_orderkey
),
SupplierStats AS (
    SELECT 
        ps_suppkey,
        COUNT(DISTINCT ps_partkey) AS unique_parts_count,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM 
        partsupp
    GROUP BY 
        ps_suppkey
),
CustomerStats AS (
    SELECT 
        c_custkey,
        SUM(o_totalprice) AS total_spent,
        COUNT(DISTINCT o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customers_count,
    SUM(ts.total_revenue) AS total_revenue,
    AVG(cs.total_spent) AS avg_customer_spending,
    SUM(ss.unique_parts_count) AS total_unique_parts,
    SUM(ss.total_supply_cost) AS total_supply_cost
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    TotalSales ts ON ts.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
LEFT JOIN 
    SupplierStats ss ON ss.ps_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT l_partkey FROM lineitem WHERE l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)))
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;
