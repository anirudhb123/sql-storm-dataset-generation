WITH RECURSIVE customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    
    UNION ALL

    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.level + 1
    FROM customer_orders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate > co.o_orderdate
),
ranked_lineitems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rnk
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_discount > 0.1
),
total_stats AS (
    SELECT 
        p.p_brand,
        SUM(ps.ps_supplycost) AS total_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY p.p_brand
)
SELECT 
    co.c_name AS customer_name,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    SUM(co.o_totalprice) AS total_spent,
    tls.total_cost,
    tls.supplier_count,
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS customer_rank
FROM customer_orders co
LEFT JOIN ranked_lineitems rli ON co.o_orderkey = rli.l_orderkey
LEFT JOIN total_stats tls ON rli.l_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = tls.p_brand LIMIT 1)
GROUP BY co.c_custkey, co.c_name, tls.total_cost, tls.supplier_count
HAVING total_spent > 1000
ORDER BY total_spent DESC
LIMIT 10;
