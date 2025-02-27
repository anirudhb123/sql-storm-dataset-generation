WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        COUNT(ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank_by_supply
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_container
),
filtered_parts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.total_available_quantity,
        rp.total_supply_cost
    FROM 
        ranked_parts rp
    WHERE 
        rp.rank_by_supply <= 5
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
part_order_details AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        customer_orders co
    JOIN 
        lineitem l ON co.o_orderkey = l.l_orderkey
    GROUP BY 
        co.c_custkey, co.c_name
)
SELECT 
    fp.p_brand,
    fp.total_available_quantity,
    fp.total_supply_cost,
    pod.c_name,
    pod.total_spent,
    pod.order_count
FROM 
    filtered_parts fp
JOIN 
    part_order_details pod ON fp.p_partkey IN (
        SELECT 
            ps.ps_partkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    )
ORDER BY 
    fp.total_supply_cost DESC, pod.total_spent DESC;
