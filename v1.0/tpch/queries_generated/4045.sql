WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
), 
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
), 
region_order_summary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    r.n_name,
    ros.order_rank,
    ros.o_totalprice,
    ros.o_orderdate,
    ss.total_supply_cost,
    ss.part_count,
    ss.part_names,
    ros.o_orderkey,
    CASE 
        WHEN ros.order_rank <= 10 THEN 'Top Order'
        ELSE 'Other Order' 
    END AS order_category
FROM 
    region r
JOIN 
    region_order_summary ros ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = r.r_name LIMIT 1)
LEFT JOIN 
    supplier_summary ss ON ss.total_supply_cost < 10000.00
WHERE 
    ss.part_count > 5
ORDER BY 
    r.r_name, ros.o_orderdate DESC;
