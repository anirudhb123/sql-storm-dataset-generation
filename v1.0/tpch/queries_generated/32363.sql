WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
  
    UNION ALL 
  
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.s_nationkey,
        sp.s_acctbal,
        sh.level + 1
    FROM 
        supplier_hierarchy sh
    JOIN 
        supplier sp ON sh.s_nationkey = sp.s_nationkey 
    WHERE 
        sp.s_acctbal > sh.s_acctbal
),
average_prices AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
top_customers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
filtered_lineitems AS (
    SELECT 
        l.*, 
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        l.l_discount > 0.2 
        AND l.l_returnflag = 'N'
)

SELECT 
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    t.c_name AS customer_name,
    t.total_spent,
    avg.avg_supplycost, 
    COUNT(DISTINCT f.l_orderkey) AS order_count
FROM 
    supplier_hierarchy s
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    top_customers t ON s.s_suppkey = t.c_custkey
JOIN 
    filtered_lineitems f ON f.l_suppkey = s.s_suppkey
JOIN 
    average_prices avg ON f.l_partkey = avg.ps_partkey
WHERE 
    s.s_acctbal IS NOT NULL
    AND t.total_spent > (SELECT AVG(total_spent) FROM top_customers)
GROUP BY 
    s.s_name, r.r_name, t.c_name, t.total_spent, avg.avg_supplycost
ORDER BY 
    t.total_spent DESC, order_count DESC;
