WITH RECURSIVE
    cust_orders AS (
        SELECT 
            c.c_custkey, 
            c.c_name, 
            COUNT(o.o_orderkey) AS order_count,
            SUM(o.o_totalprice) AS total_spent
        FROM 
            customer c 
        LEFT JOIN 
            orders o ON c.c_custkey = o.o_custkey
        GROUP BY 
            c.c_custkey, c.c_name
    ),
    part_supplier AS (
        SELECT 
            p.p_partkey,
            p.p_name,
            s.s_name,
            ps.ps_supplycost,
            ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
        FROM 
            part p
        JOIN 
            partsupp ps ON p.p_partkey = ps.ps_partkey
        JOIN 
            supplier s ON ps.ps_suppkey = s.s_suppkey
    ),
    aggregated_parts AS (
        SELECT
            ps.p_partkey,
            SUM(ps.ps_availqty) AS total_available,
            AVG(ps.ps_supplycost) AS avg_supply_cost
        FROM 
            part_supplier ps
        GROUP BY 
            ps.p_partkey
    ),
    nation_region AS (
        SELECT 
            n.n_nationkey,
            r.r_regionkey,
            r.r_name,
            COUNT(DISTINCT s.s_suppkey) AS supplier_count
        FROM 
            nation n
        JOIN 
            region r ON n.n_regionkey = r.r_regionkey
        LEFT JOIN 
            supplier s ON n.n_nationkey = s.s_nationkey
        GROUP BY 
            n.n_nationkey, r.r_regionkey, r.r_name
    )
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    pp.p_name,
    ap.total_available,
    ap.avg_supply_cost,
    nr.r_name AS region_name,
    nr.supplier_count,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE 
            CASE 
                WHEN co.total_spent < 1000 THEN 'Low Value'
                WHEN co.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Value'
                ELSE 'High Value'
            END
    END AS customer_value_desc
FROM 
    cust_orders co
LEFT JOIN 
    aggregated_parts ap ON ap.p_partkey = (
        SELECT 
            ps.p_partkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_availqty = (SELECT MAX(ps_inner.ps_availqty) FROM partsupp ps_inner)
        LIMIT 1
    )
LEFT JOIN 
    part pp ON pp.p_partkey = ap.p_partkey
JOIN 
    nation_region nr ON nr.n_nationkey = (
        SELECT 
            c.c_nationkey 
        FROM 
            customer c 
        WHERE 
            c.c_custkey = co.c_custkey
    )
WHERE 
    co.order_count > 0
ORDER BY 
    co.total_spent DESC, 
    nr.supplier_count ASC;
