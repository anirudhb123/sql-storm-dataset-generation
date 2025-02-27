WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_retailprice, 
        LENGTH(p.p_comment) AS comment_length, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    c.c_name AS customer_name, 
    o.order_count, 
    o.total_spent,
    h.total_value AS high_value_order
FROM RankedParts p
JOIN CustomerOrderStats o ON TRUE
JOIN HighValueOrders h ON o.order_count > 5
WHERE p.rank <= 3
ORDER BY p.p_brand, h.total_value DESC;
