WITH RegionalSummary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(p.p_retailprice) AS total_retail_price,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_name
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        l.l_quantity,
        l.l_extendedprice,
        SUM(l.l_discount) OVER (PARTITION BY o.o_orderkey) AS total_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT 
    rs.region_name,
    rs.total_retail_price,
    rs.supplier_count,
    rs.customer_count,
    AVG(od.o_totalprice) AS average_order_total,
    SUM(od.l_extendedprice) AS total_extended_price,
    SUM(od.total_discount) AS total_discount_given
FROM RegionalSummary rs
JOIN OrderDetails od ON rs.customer_count > 0
GROUP BY rs.region_name, rs.total_retail_price, rs.supplier_count
ORDER BY rs.total_retail_price DESC, average_order_total ASC;
