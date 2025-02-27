
WITH RECURSIVE ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
supplier_orders AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey
),
high_value_customers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spend
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    rp.p_name, 
    rp.p_mfgr, 
    rp.p_retailprice, 
    COALESCE(s.total_orders, 0) AS supplier_order_count,
    COALESCE(hvc.total_spend, 0) AS customer_spend
FROM ranked_parts rp
LEFT JOIN supplier_orders s ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN high_value_customers hvc ON hvc.c_custkey IN (
    SELECT o.o_custkey 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_partkey = rp.p_partkey
)
WHERE rp.rank <= 5
ORDER BY rp.p_retailprice DESC, hvc.total_spend DESC
FETCH FIRST 20 ROWS ONLY;
