WITH RECURSIVE sales_cte AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
part_supplier AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_available, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
ranked_sales AS (
    SELECT 
        s.c_custkey, 
        s.c_name, 
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) as sales_rank
    FROM 
        sales_cte s
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_type,
    COALESCE(ps.total_available, 0) AS available_quantity,
    COALESCE(ps.avg_supply_cost, 0.00) AS average_supply_cost,
    rs.total_sales,
    rs.sales_rank
FROM 
    part p
LEFT JOIN 
    part_supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    ranked_sales rs ON ps.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0)
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_brand = p.p_brand
    ) AND 
    EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_shipdate >= '2023-01-01'
    )
ORDER BY 
    sales_rank ASC, 
    available_quantity DESC;
