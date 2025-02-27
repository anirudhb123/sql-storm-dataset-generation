WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            WHEN l.l_returnflag IS NULL THEN 'Not Returned'
            ELSE 'Unknown'
        END AS return_status,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS line_rnk
    FROM 
        lineitem l
    WHERE 
        l.l_discount BETWEEN 0.05 AND 0.3 AND 
        l.l_extendedprice > (SELECT AVG(l2.l_extendedprice) FROM lineitem l2 WHERE l2.l_discount BETWEEN 0.05 AND 0.3)
)
SELECT 
    r.o_orderkey,
    SUM(h.l_extendedprice * (1 - h.l_discount)) AS total_revenue,
    COUNT(DISTINCT h.l_partkey) AS unique_parts_count,
    COUNT(h.l_suppkey) AS total_suppliers,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    MAX(CASE WHEN h.return_status = 'Returned' THEN h.l_quantity ELSE NULL END) AS max_returned_quantity
FROM 
    RankedOrders r
LEFT JOIN 
    HighValueLineItems h ON r.o_orderkey = h.l_orderkey
LEFT JOIN 
    partsupp ps ON h.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    r.o_orderkey
HAVING 
    SUM(h.l_extendedprice * (1 - h.l_discount)) IS NOT NULL AND 
    COUNT(DISTINCT h.l_partkey) > 1
ORDER BY 
    total_revenue DESC
LIMIT 10;
