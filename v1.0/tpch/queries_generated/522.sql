WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
region_nation AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, n.n_name
),
final_report AS (
    SELECT 
        o.o_orderkey,
        os.total_price,
        ss.s_name AS supplier_name,
        rn.r_name AS region_name,
        rn.n_name AS nation_name,
        ss.total_parts,
        ss.total_supply_cost,
        ss.avg_avail_qty,
        CASE 
            WHEN os.total_price > 1000 THEN 'High Value'
            WHEN os.total_price BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS order_value_category
    FROM 
        order_summary os
    LEFT JOIN 
        supplier_stats ss ON os.o_custkey = ss.s_suppkey
    JOIN 
        region_nation rn ON ss.s_suppkey = rn.supplier_count
    WHERE 
        ss.total_supply_cost IS NOT NULL
)

SELECT 
    fr.* 
FROM 
    final_report fr
WHERE 
    fr.region_name IS NOT NULL 
ORDER BY 
    fr.total_price DESC, fr.supplier_name ASC;

