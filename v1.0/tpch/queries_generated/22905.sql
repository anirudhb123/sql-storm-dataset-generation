WITH OrderedItems AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        o.*,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY oi.total_price DESC) AS order_rank,
        RANK() OVER (ORDER BY oi.total_price DESC) AS total_price_rank
    FROM 
        orders o
    JOIN 
        OrderedItems oi ON o.o_orderkey = oi.o_orderkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sp.total_avail_qty, 0) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(oi.total_price) AS average_order_price,
    MAX(oi.total_price) AS max_order_price,
    -- Considering NULL logic and bizarre aggregation
    SUM(CASE WHEN oi.item_count > 5 THEN 1 ELSE 0 END) * 2 AS entries_with_multiple_items,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    MAX(CASE WHEN oi.order_rank = 1 THEN oi.o_orderkey ELSE NULL END) AS highest_order_key
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    RankedOrders oi ON o.o_orderkey = oi.o_orderkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND (p.p_size IS NOT NULL OR p.p_type LIKE '%extra%')
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 
    AND MAX(oi.total_price) IS NOT NULL
ORDER BY 
    total_available_quantity DESC, 
    average_order_price ASC;
