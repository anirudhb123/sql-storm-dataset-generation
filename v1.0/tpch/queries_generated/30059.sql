WITH RECURSIVE sales_cte AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
supplier_cte AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.avg_supply_cost
    FROM 
        supplier_cte s
    WHERE 
        s.avg_supply_cost < (
            SELECT AVG(avg_supply_cost) FROM supplier_cte
        )
),
region_nation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        r.r_regionkey
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rn.r_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    COALESCE(SUM(ss.total_sales), 0) AS total_sales,
    COUNT(DISTINCT ts.s_suppkey) AS suppliers_below_avg
FROM 
    region_nation rn
LEFT JOIN 
    customer cs ON rn.n_nationkey = cs.c_nationkey
LEFT JOIN 
    sales_cte ss ON cs.c_custkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey IN (SELECT o_orderkey FROM sales_cte)
    )
LEFT JOIN 
    top_suppliers ts ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
        )
    )
GROUP BY 
    rn.r_name
HAVING 
    COUNT(DISTINCT cs.c_custkey) > 0
ORDER BY 
    total_sales DESC, rn.r_name ASC;
