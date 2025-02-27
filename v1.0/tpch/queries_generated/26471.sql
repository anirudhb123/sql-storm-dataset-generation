WITH SupplierInfo AS (
    SELECT s.s_name AS supplier_name, 
           n.n_name AS nation_name,
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, n.n_name
),
PartSummary AS (
    SELECT p.p_name,
           p.p_brand,
           p.p_type,
           SUM(ps.ps_availqty) AS total_available,
           AVG(p.p_retailprice) AS avg_retail_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name, p.p_brand, p.p_type
),
OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           SUM(l.l_tax) AS total_tax,
           COUNT(l.l_linenumber) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT si.supplier_name,
       si.nation_name,
       ps.p_name,
       ps.p_brand,
       ps.p_type,
       ps.total_available,
       ps.avg_retail_price,
       od.total_sales,
       od.total_tax,
       od.lineitem_count
FROM SupplierInfo si
JOIN PartSummary ps ON si.part_count > 10
JOIN OrderDetails od ON od.lineitem_count > 5
ORDER BY si.nation_name, total_sales DESC;
