WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS status_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
), 
supplier_parts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    NULLIF(p.p_comment, '') AS sanitized_comment,
    COALESCE(num_orders.total_orders, 0) AS orders_count,
    COALESCE(suppliers.total_available, 0) AS suppliers_available,
    ROUND(CAST(num_orders.total_spent AS decimal) / GREATEST(NULLIF(COUNT(DISTINCT o.o_custkey), 0), 1), 2) AS average_spent,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS order_status,
    status_rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    ranked_orders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    customer_orders num_orders ON l.l_orderkey = num_orders.total_orders
LEFT JOIN 
    supplier_parts suppliers ON p.p_partkey = suppliers.ps_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_sub.p_retailprice) FROM part p_sub)
    AND p.p_size IS NOT NULL 
ORDER BY 
    p.p_retailprice DESC,
    order_status,
    suppliers.total_available DESC
LIMIT 50;
