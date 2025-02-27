
WITH RECURSIVE CustomerOrderCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
) 

SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    COALESCE(MAX(co.total_spent), 0) AS customer_spending
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    CustomerOrderCTE co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'A%')
WHERE 
    s.s_acctbal IS NOT NULL 
    AND p.p_retailprice BETWEEN 10.00 AND 100.00 
    AND p.p_size IN (
        SELECT
            DISTINCT p_size 
        FROM
            part 
        WHERE
            p_type = 'TYPE1'
            AND p_mfgr = 'MFGR1'
    )
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > ALL (
        SELECT 
            AVG(ps_availqty) 
        FROM 
            partsupp 
        GROUP BY 
            ps_partkey
    )
ORDER BY 
    customer_spending DESC,
    supplier_count ASC;
