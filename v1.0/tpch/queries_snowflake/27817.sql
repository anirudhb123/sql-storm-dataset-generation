WITH formatted_part_names AS (
    SELECT 
        p_partkey,
        CONCAT('Part: ', TRIM(p_name), ' - Type: ', TRIM(p_type), ' - Brand: ', TRIM(p_brand)) AS full_description
    FROM part
),
customer_order_summary AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
),
supplier_part_summary AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    cp.c_name AS customer_name,
    cps.total_orders,
    cps.total_spent,
    sps.s_name AS supplier_name,
    sps.supplied_parts,
    sps.total_available_qty,
    fp.full_description
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
JOIN customer_order_summary cps ON cps.total_orders > 0
JOIN customer cp ON cp.c_name = cps.c_name
JOIN supplier_part_summary sps ON sps.supplied_parts > 1
JOIN formatted_part_names fp ON fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_name = sps.s_name ORDER BY ps.ps_supplycost DESC LIMIT 1)
WHERE r.r_name LIKE 'N%' 
ORDER BY r.r_name, ns.n_name, cp.c_name;
