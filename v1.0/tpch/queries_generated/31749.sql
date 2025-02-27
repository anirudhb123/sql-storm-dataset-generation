WITH RECURSIVE TotalSupplies AS (
    SELECT ps_partkey, SUM(ps_availqty) AS total_available
    FROM partsupp
    GROUP BY ps_partkey
), FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), OrderStats AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderstatus
), CombinedResults AS (
    SELECT 
        ps.ps_partkey, 
        p.p_name, 
        COALESCE(ts.total_available, 0) AS available_quantity,
        fs.nation_name,
        os.total_price,
        os.order_rank
    FROM part p
    LEFT OUTER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN TotalSupplies ts ON ps.ps_partkey = ts.ps_partkey
    LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey = ps.ps_suppkey
    LEFT JOIN OrderStats os ON os.o_orderkey = ps.ps_partkey 
    WHERE (ts.total_available IS NULL OR ts.total_available > 100)
      AND (os.order_rank IS NULL OR os.order_rank <= 5)
)
SELECT 
    c.c_name AS customer_name,
    cr.nation_name AS customer_nation,
    SUM(cr.available_quantity) AS total_available_parts,
    COUNT(DISTINCT cr.ps_partkey) AS unique_parts_count,
    AVG(cr.total_price) AS average_order_value
FROM CombinedResults cr
JOIN customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = cr.nation_name)
GROUP BY c.c_name, cr.nation_name
HAVING SUM(cr.available_quantity) > 0
ORDER BY total_available_parts DESC;
