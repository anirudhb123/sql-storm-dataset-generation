WITH RankedSuppliers AS (
    SELECT 
        s_name,
        s_nationkey,
        s_acctbal,
        RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM 
        supplier
    WHERE 
        s_acctbal IS NOT NULL
), 

HighValueParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_retailprice,
        CASE 
            WHEN p_retailprice > 1000 THEN 'High'
            WHEN p_retailprice BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS price_category
    FROM 
        part
    WHERE 
        p_retailprice >= 0
), 

OrderStats AS (
    SELECT 
        o_custkey,
        SUM(o_totalprice) AS total_spent,
        COUNT(o_orderkey) AS order_count
    FROM 
        orders
    GROUP BY 
        o_custkey
    HAVING 
        COUNT(o_orderkey) > 0
)

SELECT 
    c.c_name AS customer_name,
    n.n_name AS nation,
    ps.ps_availqty AS available_quantity,
    hp.p_name AS part_name,
    hp.price_category,
    RANK() OVER (PARTITION BY hp.price_category ORDER BY ps.ps_supplycost) AS price_rank,
    SUM(ls.l_quantity * (1 - ls.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(ls.l_quantity) IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    customer c 
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem ls ON o.o_orderkey = ls.l_orderkey
LEFT JOIN 
    partsupp ps ON ls.l_partkey = ps.ps_partkey
JOIN 
    HighValueParts hp ON ps.ps_partkey = hp.p_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_nationkey = n.n_nationkey AND rs.rank = 1
WHERE 
    ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
GROUP BY 
    c.c_name, n.n_name, ps.ps_availqty, hp.p_name, hp.price_category
HAVING 
    total_revenue > 0
ORDER BY 
    customer_name, nation;
