WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),

CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    pd.p_name, 
    pd.p_brand, 
    pd.supplier_count, 
    co.c_name, 
    co.total_orders, 
    co.total_spent
FROM 
    PartDetails pd
JOIN 
    CustomerOrders co ON pd.p_container LIKE '%' || co.c_name || '%'
WHERE 
    pd.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    pd.supplier_count DESC, 
    co.total_spent DESC;
