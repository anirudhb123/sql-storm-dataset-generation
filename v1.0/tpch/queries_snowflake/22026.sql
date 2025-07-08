
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
),
SupplierCost AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
    GROUP BY 
        l.l_orderkey
),
SalesRanked AS (
    SELECT 
        nation_name,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    sr.nation_name,
    sr.total_sales,
    CASE
        WHEN sr.total_sales > (SELECT AVG(total_sales) FROM RegionalSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance,
    sc.total_supply_cost,
    l.distinct_parts,
    l.net_revenue
FROM 
    SalesRanked sr
LEFT JOIN 
    SupplierCost sc ON sr.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey IN 
                                            (SELECT c.c_nationkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey 
                                             WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l) LIMIT 1))
LEFT JOIN 
    LineItemStats l ON sr.nation_name = (SELECT n.n_name FROM nation n JOIN customer c ON n.n_nationkey = c.c_nationkey 
                                            WHERE c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey LIMIT 1))
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.total_sales DESC;
