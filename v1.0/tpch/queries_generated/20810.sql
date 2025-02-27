WITH ranked_orders AS (
    SELECT o.o_orderkey, l.l_partkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
), 
supplier_summary AS (
    SELECT ps.s_suppkey, SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
filtered_suppliers AS (
    SELECT s.*, ss.total_available, ss.unique_parts
    FROM supplier s
    LEFT JOIN supplier_summary ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.total_available IS NOT NULL OR s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = s.s_nationkey
    )
), 
high_value_orders AS (
    SELECT r.r_name, SUM(oo.o_totalprice) AS total_sales
    FROM ranked_orders oo
    JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey 
                                       FROM customer c WHERE c.c_custkey = oo.o_custkey)
    JOIN region r ON r.r_regionkey = n.n_regionkey
    WHERE oo.rn = 1 AND oo.o_totalprice > 1000
    GROUP BY r.r_name
)
SELECT fs.s_name, COALESCE(fs.total_available, 0) AS available_qty, 
       COALESCE(hvo.total_sales, 0) AS sales,
       CASE WHEN fs.unique_parts > 10 THEN 'Diverse Supplier' ELSE 'Limited Offer' END AS supplier_type
FROM filtered_suppliers fs
FULL OUTER JOIN high_value_orders hvo ON fs.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
    ) AND ps.ps_availqty > 100
    LIMIT 1
)
ORDER BY fs.s_name, hvo.total_sales DESC;
