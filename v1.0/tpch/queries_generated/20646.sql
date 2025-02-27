WITH Sales_CTE AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        c.c_custkey
),
Top_Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        sc.total_sales
    FROM 
        customer c
    JOIN 
        Sales_CTE sc ON c.c_custkey = sc.c_custkey
    WHERE 
        sc.sales_rank <= 10
),
Supplier_Stats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    tc.c_name,
    tc.total_sales,
    ns.n_name AS supplier_nation,
    ss.parts_supplied,
    ss.total_supply_cost,
    CASE 
        WHEN ss.parts_supplied IS NULL THEN 'No Parts'
        WHEN ss.total_supply_cost > 50000 THEN 'High Supply Cost'
        ELSE 'Average Supply Cost'
    END AS supply_assessment
FROM 
    Top_Customers tc
LEFT JOIN 
    Supplier_Stats ss ON ss.parts_supplied > 5
INNER JOIN 
    nations ns ON tc.c_custkey % 15 = ns.n_nationkey
WHERE 
    (tc.total_sales > 10000 OR ss.total_supply_cost IS NULL)
    AND NOT EXISTS (SELECT 1 FROM lineitem l WHERE l.l_returnflag = 'R' AND l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey))
ORDER BY 
    tc.total_sales DESC,
    ns.region_name ASC;
