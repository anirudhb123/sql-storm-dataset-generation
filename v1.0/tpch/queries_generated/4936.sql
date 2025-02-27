WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
), 
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, 
        s.s_name
), 
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    COALESCE(si.s_name, 'No Supplier') AS supplier_name,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    RANK() OVER (ORDER BY COALESCE(cs.total_spent, 0) DESC) AS customer_rank,
    COUNT(DISTINCT oi.o_orderkey) AS order_count,
    CASE 
        WHEN p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) THEN 'Above Average'
        ELSE 'Below Average'
    END AS price_evaluation
FROM 
    part p
LEFT OUTER JOIN 
    SupplierInfo si ON p.p_partkey = si.ps_partkey
LEFT OUTER JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT OUTER JOIN 
    RankedOrders oi ON li.l_orderkey = oi.o_orderkey
LEFT OUTER JOIN 
    CustomerSpending cs ON li.l_suppkey = cs.c_custkey
WHERE 
    p.p_size IS NOT NULL 
    AND p.p_comment LIKE '%special%'
GROUP BY 
    p.p_name, si.s_name, cs.total_spent
HAVING 
    COUNT(DISTINCT oi.o_orderkey) > 0
ORDER BY 
    customer_rank ASC, order_count DESC;
