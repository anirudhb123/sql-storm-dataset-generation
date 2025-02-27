WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, 
           SUBSTRING(s.s_comment FROM 1 FOR 20) AS short_comment, 
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name AS customer_name, 
           COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
), 
PartSummary AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_partkey) AS supplier_count, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
) 
SELECT sd.s_name, sd.nation_name, od.customer_name, od.o_orderdate, 
       ps.p_name, ps.supplier_count, ps.avg_supplycost, 
       sd.short_comment, sd.comment_length
FROM SupplierDetails sd
JOIN OrderDetails od ON sd.s_suppkey = od.o_orderkey % (SELECT COUNT(s_suppkey) FROM supplier)
JOIN PartSummary ps ON sd.s_suppkey <= ps.supplier_count
WHERE sd.comment_length > 50 
ORDER BY od.o_orderdate DESC, ps.avg_supplycost ASC;
