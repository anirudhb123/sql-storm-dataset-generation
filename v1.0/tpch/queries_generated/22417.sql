WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
product_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_size, 0), 1) AS adjusted_size
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price,
    ss.unique_parts,
    ss.total_supplycost,
    p.p_name,
    DENSE_RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.o_orderdate DESC) AS order_density
FROM 
    customer_orders co
JOIN 
    lineitem l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier_summary ss ON ss.unique_parts > 5
JOIN 
    product_details p ON p.p_partkey = l.l_partkey
WHERE 
    co.order_rank = 1 
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, ss.unique_parts, ss.total_supplycost, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_extended) FROM (SELECT SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_extended FROM lineitem l2 GROUP BY l2.l_orderkey) AS avg_totals)
ORDER BY 
    order_density DESC, co.o_orderdate;
