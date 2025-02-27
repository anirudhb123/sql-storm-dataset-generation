WITH StringAggregation AS (
    SELECT 
        p.p_partkey, 
        CONCAT_WS(',', p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
                    p.p_container, p.p_comment) AS full_description,
        LENGTH(CONCAT_WS(',', p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
        p.p_container, p.p_comment)) AS description_length,
        SUM(CASE WHEN ps.ps_supplycost < 100 THEN 1 ELSE 0 END) AS low_cost_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
FilteredVendors AS (
    SELECT 
        s.s_name, 
        CONCAT(s.s_name, ' [', s.s_phone, ']') AS vendor_contact
    FROM supplier s
    WHERE LENGTH(s.s_name) > 10
    ORDER BY s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
)
SELECT 
    sa.p_partkey, 
    sa.full_description, 
    sa.description_length, 
    sa.low_cost_suppliers, 
    fv.vendor_contact,
    co.c_name, 
    co.order_count, 
    co.average_order_value
FROM StringAggregation sa
JOIN FilteredVendors fv ON sa.low_cost_suppliers > 2
JOIN CustomerOrders co ON co.order_count > 5
ORDER BY sa.description_length DESC, co.average_order_value DESC;
