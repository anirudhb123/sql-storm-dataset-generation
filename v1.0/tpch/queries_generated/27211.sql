WITH String_Processing AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(p.p_name) AS name_length,
        REPLACE(p.p_comment, 'the', 'THE') AS modified_comment
    FROM part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container LIKE 'Box%')
),
Aggregated_Nations AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
Customer_Orders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_orderstatus, '|') AS unique_order_statuses
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
)
SELECT 
    sp.upper_name,
    sp.lower_comment,
    sp.name_length,
    sp.modified_comment,
    an.n_name AS nation_name,
    an.supplier_count,
    an.supplier_names,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    co.unique_order_statuses
FROM String_Processing sp
CROSS JOIN Aggregated_Nations an
CROSS JOIN Customer_Orders co
WHERE sp.name_length > 10 AND co.total_spent > 1000
ORDER BY sp.name_length DESC, co.total_spent DESC;
