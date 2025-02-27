WITH PreparedData AS (
    SELECT 
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        o.o_orderdate,
        r.r_name AS region_name,
        n.n_name AS nation_name
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    customer_name,
    supplier_name,
    part_name,
    AVG(l_quantity) AS avg_quantity,
    SUM(l_extendedprice) AS total_extended_price,
    ROUND(SUM(l_discount * l_extendedprice), 2) AS total_discount_value,
    ROUND(SUM(l_tax * l_extendedprice), 2) AS total_tax_value,
    COUNT(DISTINCT o_orderdate) AS order_count,
    region_name,
    nation_name
FROM PreparedData
WHERE l_discount > 0.05
GROUP BY customer_name, supplier_name, part_name, region_name, nation_name
ORDER BY total_extended_price DESC, avg_quantity ASC;
