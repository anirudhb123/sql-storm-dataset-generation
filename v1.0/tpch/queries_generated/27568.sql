WITH PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finished'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown'
        END AS order_status,
        SUBSTRING(o.o_comment, 1, 20) AS order_comment_preview
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_brand LIKE 'Brand#%'
)
SELECT 
    p_name,
    p_type,
    COUNT(DISTINCT o_orderkey) AS order_count,
    AVG(ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT supplier_name, ', ') AS suppliers,
    STRING_AGG(DISTINCT customer_name, ', ') AS customers,
    MAX(order_status) AS max_order_status,
    MIN(order_comment_preview) AS earliest_comment_preview
FROM 
    PartInfo
GROUP BY 
    p_name, p_type
ORDER BY 
    order_count DESC, avg_supply_cost DESC
LIMIT 10;
