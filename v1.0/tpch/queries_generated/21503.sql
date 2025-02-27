WITH RECURSIVE price_analysis AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS cost_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_supplycost IS NOT NULL
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(DISTINCT(ps.ps_partkey)) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
),
high_value_sales AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        total_sales > 10000
)
SELECT 
    s.s_name,
    pi.p_name,
    ps.ps_availqty,
    CASE 
        WHEN ps.ps_supplycost IS NULL THEN 'No Cost Available'
        ELSE CAST(ps.ps_supplycost * 1.20 AS DECIMAL(12, 2)) 
    END AS adjusted_cost,
    RANK() OVER (PARTITION BY pi.p_partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank,
    ha.total_sales
FROM 
    supplier_info s
LEFT JOIN 
    price_analysis ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part pi ON ps.ps_partkey = pi.p_partkey
LEFT JOIN 
    high_value_sales ha ON ha.o_orderkey = (SELECT MAX(o.o_orderkey) 
                                             FROM orders o 
                                             WHERE o.o_orderdate <= CURRENT_DATE 
                                             AND EXISTS (SELECT 1 
                                                         FROM lineitem li 
                                                         WHERE li.l_orderkey = o.o_orderkey 
                                                         AND li.l_partkey = ps.ps_partkey))
ORDER BY 
    s.s_name, supply_rank ASC 
FETCH FIRST 50 ROWS ONLY;
