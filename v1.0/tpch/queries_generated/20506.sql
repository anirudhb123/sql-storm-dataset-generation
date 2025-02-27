WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            WHEN o.o_orderstatus = 'F' THEN 'Filled'
            ELSE 'Other'
        END AS status_label
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
),
part_summary AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS total_quantity_sold,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.region_name,
    n.n_name,
    si.s_name,
    po.o_orderkey,
    po.total_sales,
    pi.total_quantity_sold,
    COUNT(DISTINCT po.o_orderkey) OVER (PARTITION BY r.r_regionkey) AS total_orders_in_region,
    SUM(po.total_sales) OVER (PARTITION BY r.r_regionkey ORDER BY pi.total_quantity_sold DESC) AS cumulative_sales,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY po.total_sales DESC) AS sales_rank
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier_info si ON si.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr LIKE 'Manufacturer%'))
LEFT JOIN 
    part_summary pi ON si.s_suppkey = pi.p_partkey
INNER JOIN 
    ranked_orders po ON po.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey) LIMIT 1)
WHERE 
    pi.total_sales IS NOT NULL AND
    si.num_parts_supplied >= 10 AND 
    (po.status_label IS NOT NULL OR po.total_sales > 1000)
ORDER BY 
    r.region_name, 
    n.n_name, 
    po.total_sales DESC, 
    sales_rank;
