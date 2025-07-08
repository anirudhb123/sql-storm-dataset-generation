WITH RECURSIVE price_analysis AS (
    SELECT 
        p_partkey,
        p_name,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS price_rank,
        (SELECT AVG(p_retailprice) FROM part) AS avg_price
    FROM part
), 
high_value_suppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        s_acctbal,
        CASE 
            WHEN s_acctbal IS NULL THEN 'Unknown'
            WHEN s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) THEN 'High Value'
            ELSE 'Low Value'
        END AS supplier_category
    FROM supplier
    WHERE s_acctbal IS NOT NULL 
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = 1)
    GROUP BY c.c_custkey
), 
inner_details AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_extendedprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY li.l_extendedprice DESC) AS segment_rank
    FROM lineitem li
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE li.l_returnflag = 'N' AND li.l_discount BETWEEN 0.1 AND 0.5
)

SELECT 
    pa.p_name,
    pa.p_retailprice,
    hv.s_name,
    hv.s_acctbal,
    co.total_orders,
    co.total_spent,
    id.l_quantity,
    id.l_extendedprice,
    CASE 
        WHEN pa.price_rank = 1 THEN 'Most Expensive'
        WHEN pa.p_retailprice > pa.avg_price THEN 'Expensive'
        ELSE 'Affordable'
    END AS price_category,
    id.c_mktsegment
FROM price_analysis pa
FULL OUTER JOIN high_value_suppliers hv ON pa.p_partkey = (
    SELECT ps_partkey 
    FROM partsupp ps 
    WHERE ps_suppkey = hv.s_suppkey 
    ORDER BY ps_supplycost DESC 
    LIMIT 1
)
JOIN customer_orders co ON co.c_custkey = hv.s_suppkey
JOIN inner_details id ON id.l_partkey = pa.p_partkey
WHERE 
    (co.total_orders IS NOT NULL AND co.total_orders > 5)
    OR (hv.s_acctbal IS NOT NULL AND hv.s_acctbal > 10000)
ORDER BY 
    pa.p_retailprice DESC, hv.s_acctbal ASC, co.total_spent DESC;
