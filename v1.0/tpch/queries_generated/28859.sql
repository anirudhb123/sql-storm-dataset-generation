WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        STRING_AGG(DISTINCT p.p_name, ', ') AS aggregated_names,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(s.s_acctbal) AS average_supplier_balance,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        p.p_size > 10 AND 
        s.s_acctbal > 1000
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sa.aggregated_names,
    sa.total_available_quantity,
    sa.average_supplier_balance,
    sa.first_order_date,
    sa.last_order_date
FROM 
    StringAggregation sa
JOIN 
    supplier s ON sa.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    region_name, nation_name;
