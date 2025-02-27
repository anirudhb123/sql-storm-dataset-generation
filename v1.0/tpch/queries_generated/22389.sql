WITH aggregated_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), filtered_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), divergent_nations AS (
    SELECT
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
), final_report AS (
    SELECT 
        a.p_partkey,
        a.p_name,
        a.total_supplycost,
        o.total_price,
        n.n_name,
        (CASE 
            WHEN o.total_price IS NULL THEN 'No Orders'
            WHEN a.total_supplycost > o.total_price THEN 'Costs Exceed Revenue'
            ELSE 'Revenue Exceeds or Equals Costs' 
        END) AS cost_revenue_comparison
    FROM 
        aggregated_data a
    LEFT JOIN 
        filtered_orders o ON a.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = a.total_supplycost LIMIT 1)
    FULL OUTER JOIN 
        divergent_nations n ON a.p_partkey % 2 = 0 AND n.supplier_count > 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.total_supplycost, 0) AS total_supplycost,
    p.total_price,
    n.n_name,
    n.cost_revenue_comparison
FROM 
    part p
LEFT JOIN 
    final_report r ON p.p_partkey = r.p_partkey
LEFT JOIN 
    divergent_nations n ON n.n_name LIKE '%land%'
ORDER BY 
    total_supplycost DESC, total_price ASC;
