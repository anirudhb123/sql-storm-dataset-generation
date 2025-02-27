WITH CTE_Customer_Supplier AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        s.s_suppkey, 
        s.s_name, 
        ROW_NUMBER() OVER(PARTITION BY c.c_custkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        customer c
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
), 

CTE_Part_Supplier AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_availqty,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)


SELECT 
    p.p_name, 
    COALESCE(cte.rank, 0) AS customer_rank, 
    cte.c_name, 
    ps.total_availqty,
    p.p_retailprice - (1 - CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END) * p.p_retailprice AS discounted_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS order_rank
FROM 
    part p
LEFT JOIN 
    CTE_Part_Supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CTE_Customer_Supplier cte ON o.o_custkey = cte.c_custkey AND cte.rank = 1
WHERE 
    p.p_retailprice IS NOT NULL
    AND (SELECT COUNT(*) FROM partsupp WHERE ps_supplycost > 100) <= 50
GROUP BY 
    p.p_partkey, cte.c_name, cte.rank, ps.total_availqty, p.p_retailprice
HAVING 
    SUM(l.l_quantity) > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_returnflag = 'N') 
    OR COUNT(DISTINCT o.o_orderkey) IS NOT NULL
ORDER BY 
    discounted_price DESC, order_rank ASC;
