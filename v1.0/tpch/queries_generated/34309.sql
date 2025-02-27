WITH RECURSIVE Sales_CTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
Supplier_Aggregates AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey
),
Filtered_Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        n.n_name LIKE 'A%' OR r.r_comment IS NOT NULL
),
Top_Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    fn.n_nationkey,
    fn.n_name,
    fn.r_name,
    tc.c_name,
    SUM(sc.total_sales) AS nation_total_sales,
    sa.total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    Filtered_Nations fn
LEFT JOIN 
    Top_Customers tc ON fn.n_nationkey = tc.c_custkey
LEFT JOIN 
    Sales_CTE sc ON tc.c_custkey = sc.o_orderkey
LEFT JOIN 
    Supplier_Aggregates sa ON sa.s_suppkey = tc.c_custkey
WHERE 
    nation_total_sales IS NOT NULL OR total_supply_cost IS NOT NULL
GROUP BY 
    fn.n_nationkey, fn.n_name, fn.r_name, tc.c_name, sa.total_supply_cost
ORDER BY 
    nation_total_sales DESC, order_count ASC;
