WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderstatus IN ('F', 'P')
), 
high_value_customers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 100000
), 
supplier_part_stats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 10
),
nation_supplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        s.s_suppkey,
        s.s_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    SUM(CASE WHEN l.l_discount < 0.05 THEN l.l_extendedprice ELSE 0 END) AS low_discount_sales,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_mktsegment = 'BUILDING') AS building_customers,
    COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_mktsegment IS NULL) AS null_segment_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    high_value_customers c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate BETWEEN '2022-01-01' AND '2023-10-01'
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    r.r_name
HAVING 
    SUM(l.l_extendedprice) > (SELECT AVG(total_spent) FROM high_value_customers)
ORDER BY 
    low_discount_sales DESC, avg_order_value ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
