WITH RecursivePartNames AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        REPLACE(LOWER(p.p_name), ' ', '') AS processed_name
    FROM part p
    UNION ALL
    SELECT 
        p.p_partkey, 
        CONCAT(r.processed_name, '_', SUBSTR(p.p_name, INSTR(p.p_name, ' ') + 1)) AS processed_name
    FROM part p
    JOIN RecursivePartNames r ON p.p_partkey = r.p_partkey
    WHERE INSTR(p.p_name, ' ') > 0
), SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COALESCE(NULLIF(UPPER(s.s_comment), ''), 'No Comment') AS supplier_comment
    FROM supplier s
), OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    rpn.processed_name, 
    sd.supplier_comment, 
    os.total_revenue
FROM RecursivePartNames rpn
JOIN SupplierDetails sd ON LENGTH(rpn.processed_name) % 2 = 0
JOIN OrderSummary os ON os.total_revenue > 50000
WHERE rpn.processed_name LIKE '%part%'
ORDER BY os.total_revenue DESC
LIMIT 10;
