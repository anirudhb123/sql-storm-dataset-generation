
WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
high_value_customers AS (
    SELECT 
        cust.c_custkey,
        cust.order_count,
        cust.total_spent
    FROM 
        customer_orders cust
    WHERE 
        cust.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
)
SELECT 
    np.n_name,
    r.r_name,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customer_count,
    COALESCE(SUM(ps.total_available), 0) AS total_available_parts,
    COUNT(DISTINCT rp.p_partkey) AS unique_parts_ranking,
    LISTAGG(DISTINCT rp.p_name, ', ') WITHIN GROUP (ORDER BY rp.p_name) AS ranked_part_names
FROM 
    high_value_customers hvc
JOIN customer c ON hvc.c_custkey = c.c_custkey
JOIN nation np ON c.c_nationkey = np.n_nationkey
JOIN region r ON np.n_regionkey = r.r_regionkey
LEFT JOIN supplier_summary ps ON r.r_regionkey = ps.s_suppkey
LEFT JOIN ranked_parts rp ON rp.rank <= 5
GROUP BY 
    np.n_name, r.r_name
HAVING 
    COUNT(DISTINCT rp.p_partkey) > 0
ORDER BY 
    unique_parts_ranking DESC NULLS LAST;
