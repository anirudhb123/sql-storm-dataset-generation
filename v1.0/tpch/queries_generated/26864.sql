WITH EnhancedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(p.p_name, ' - ', p.p_brand) AS part_description,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            WHEN p.p_size > 20 THEN 'Large'
        END AS size_category
    FROM part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT s.s_comment) AS all_comments
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ep.p_partkey,
    ep.part_description,
    ss.s_name AS supplier_name,
    ss.total_parts,
    ss.total_supply_cost,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    co.first_order_date,
    co.last_order_date,
    ep.comment_length,
    ep.size_category
FROM EnhancedParts ep
JOIN SupplierStats ss ON ep.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
JOIN CustomerOrders co ON co.total_spent > 1000
ORDER BY ep.p_retailprice DESC, co.order_count DESC;
