
WITH RECURSIVE RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
OrderDetail AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        r.c_name,
        COUNT(l.l_orderkey) AS line_count
    FROM orders o
    JOIN RankedOrders r ON o.o_orderkey = r.o_orderkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE r.order_rank <= 5
    GROUP BY o.o_orderkey, o.o_totalprice, r.c_name
)
SELECT 
    DISTINCT p.p_name,
    p.p_container,
    COALESCE(s.total_supply_value, 0) AS supplier_value,
    COALESCE(fo.line_count, 0) AS order_line_count,
    RF.total_line_value
FROM part p
LEFT JOIN HighValueSuppliers s ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 10 ORDER BY ps.ps_supplycost ASC LIMIT 1)
LEFT JOIN FilteredOrders fo ON fo.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
LEFT JOIN OrderDetail RF ON RF.l_orderkey = fo.o_orderkey AND RF.l_partkey = p.p_partkey
WHERE p.p_retailprice BETWEEN (SELECT MIN(p_retailprice) FROM part) AND (SELECT MAX(p_retailprice) FROM part)
AND (s.total_supply_value IS NOT NULL OR fo.line_count IS NULL)
ORDER BY supplier_value DESC, order_line_count ASC;
