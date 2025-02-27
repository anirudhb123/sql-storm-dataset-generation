WITH supplier_part_details AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
nation_supplier AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
),
order_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    spd.supplier_name,
    spd.part_name,
    ns.nation_name,
    ns.supplier_count,
    ns.total_supply_cost,
    os.order_count,
    os.total_order_value,
    os.avg_order_value
FROM 
    supplier_part_details spd
JOIN 
    nation_supplier ns ON spd.supplier_name IN (
        SELECT s.s_name 
        FROM supplier s 
        JOIN nation n ON s.s_nationkey = n.n_nationkey
    )
JOIN 
    order_summary os ON os.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey
    )
ORDER BY 
    ns.total_supply_cost DESC, 
    os.total_order_value DESC
LIMIT 100;
