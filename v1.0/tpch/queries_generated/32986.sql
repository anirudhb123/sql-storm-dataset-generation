WITH RECURSIVE Sales_Rank AS (
    SELECT 
        o.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.c_custkey, c.c_name
),
Top_Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        sr.total_sales
    FROM 
        customer c
    JOIN 
        Sales_Rank sr ON c.c_custkey = sr.c_custkey
    WHERE 
        sr.sales_rank <= 10
),
Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    tc.c_name,
    tc.total_sales,
    ss.total_supply_cost,
    CASE 
        WHEN ss.total_parts IS NULL THEN 'No Parts'
        WHEN ss.total_parts = 0 THEN 'No Supplies'
        ELSE 'Supplied Parts Count: ' || ss.total_parts
    END AS part_info,
    nn.n_name AS nation_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity
FROM 
    Top_Customers tc
LEFT JOIN 
    nation nn ON nn.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = tc.c_custkey)
LEFT JOIN 
    orders o ON o.o_custkey = tc.c_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    Supplier_Summary ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ANY(SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey))
GROUP BY 
    tc.c_name, tc.total_sales, ss.total_supply_cost, ss.total_parts, nn.n_name
ORDER BY 
    tc.total_sales DESC, total_supply_cost ASC;
