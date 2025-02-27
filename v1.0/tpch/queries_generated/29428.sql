WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    si.s_name,
    si.nation_name,
    si.region_name,
    co.c_name,
    co.order_count,
    co.total_spent,
    co.avg_order_value
FROM ranked_parts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN supplier_info si ON ps.ps_suppkey = si.s_suppkey
JOIN lineitem li ON ps.ps_partkey = li.l_partkey
JOIN customer_orders co ON li.l_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE rp.price_rank <= 5
ORDER BY rp.p_retailprice DESC, co.total_spent DESC;
