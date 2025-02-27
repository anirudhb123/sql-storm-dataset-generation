WITH RECURSIVE revenue_cte AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),
supplier_part_stats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
top_regions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(p.p_retailprice) AS total_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        SUM(p.p_retailprice) > 1000000
),
final_report AS (
    SELECT 
        c.c_name,
        r.r_name,
        s.s_name,
        r.total_value,
        rs.total_revenue
    FROM 
        top_regions r
    JOIN 
        supplier s ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = s.s_suppkey LIMIT 1)
    JOIN 
        revenue_cte rs ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p ORDER BY p.p_retailprice LIMIT 10))
    JOIN 
        customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_quantity > 50 LIMIT 1)) 
)
SELECT 
    fr.c_name AS customer_name,
    fr.r_name AS region_name,
    fr.s_name AS supplier_name,
    fr.total_value AS region_total_value,
    fr.total_revenue AS customer_total_revenue
FROM 
    final_report fr
ORDER BY 
    fr.total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
