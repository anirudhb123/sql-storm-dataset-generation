WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
PartAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    n.n_name,
    p.p_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END), 0) AS return_count,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(l.l_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice) DESC) AS rank_by_sales
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    PartAvailability p ON l.l_partkey = p.p_partkey
WHERE 
    (s.s_acctbal IS NOT NULL OR s.s_comment IS NULL)
    AND p.total_avail_qty > (SELECT AVG(total_avail_qty) FROM PartAvailability) 
    AND (n.n_name LIKE 'N%' OR n.n_name LIKE '%land')
GROUP BY 
    n.n_name, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    n.n_name, total_quantity DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
