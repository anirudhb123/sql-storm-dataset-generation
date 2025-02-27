WITH RECURSIVE supplier_cust_activity AS (
    SELECT 
        s.s_suppkey,
        c.c_custkey,
        s.s_name,
        c.c_name,
        SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem ON ps.ps_partkey = lineitem.l_partkey
    JOIN 
        orders o ON lineitem.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment NOT LIKE '%prime%')
    GROUP BY 
        s.s_suppkey, c.c_custkey, s.s_name, c.c_name
    HAVING 
        SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) > 1000
    UNION ALL 
    SELECT 
        s.s_suppkey,
        c.c_custkey,
        s.s_name,
        c.c_name,
        SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) DESC) AS rank
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem ON ps.ps_partkey = lineitem.l_partkey
    LEFT JOIN 
        orders o ON lineitem.l_orderkey = o.o_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal IS NOT NULL 
        AND ps.ps_availqty > 5
        AND (lineitem.l_returnflag IS NULL OR lineitem.l_returnflag <> 'R')
    GROUP BY 
        s.s_suppkey, c.c_custkey, s.s_name, c.c_name
    HAVING 
        SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) < 500
)
SELECT 
    s.s_suppkey,
    s.s_name,
    SUM(s.total_spent) AS grand_total_spent,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    CASE 
        WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN SUM(s.total_spent) / COUNT(DISTINCT c.c_custkey)
        ELSE 0
    END AS avg_spent_per_customer
FROM 
    supplier_cust_activity s
JOIN 
    customer c ON s.c_custkey = c.c_custkey
GROUP BY 
    s.s_suppkey, s.s_name
ORDER BY 
    grand_total_spent DESC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM supplier) / 2
;
