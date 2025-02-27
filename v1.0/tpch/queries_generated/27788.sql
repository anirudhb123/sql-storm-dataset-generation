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
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(m.n_name, ' (', r.r_name, ')') AS supplier_location,
        STRING_AGG(CONCAT(s.s_name, ': ', s.s_comment), '; ') AS supplier_comments
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment, ps.ps_availqty, ps.ps_supplycost, n.n_name, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
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
    pd.p_mfgr,
    pd.p_brand,
    pd.p_type,
    pd.p_retailprice,
    pd.supplier_location,
    pd.supplier_comments,
    co.c_name,
    co.total_orders,
    co.total_spent
FROM 
    PartDetails pd
JOIN 
    CustomerOrders co ON pd.supplier_location LIKE '%' || co.c_name || '%'
WHERE 
    pd.p_retailprice > 100.00
ORDER BY 
    co.total_spent DESC, pd.p_retailprice ASC
LIMIT 50;
