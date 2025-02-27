WITH part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        SUM(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_supplycost ELSE 0 END) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT p.p_brand, ', ') AS distinct_brands
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    'Part' AS entity_type,
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.total_supply_cost,
    pd.supplier_count,
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    co.distinct_brands
FROM 
    part_details pd
JOIN 
    customer_orders co ON pd.p_brand LIKE '%' || co.distinct_brands || '%'
WHERE 
    pd.total_supply_cost > 1000 
ORDER BY 
    pd.total_supply_cost DESC, co.total_spent DESC;
