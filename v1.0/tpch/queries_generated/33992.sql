WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_order_value, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY c.c_nationkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, pt.total_availqty
    FROM part p
    LEFT JOIN SupplierStats pt ON p.p_partkey = pt.s_suppkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT nh.n_name, os.total_order_value, os.order_count, 
       COALESCE(fp.total_availqty, 0) AS available_quantity,
       ROW_NUMBER() OVER (PARTITION BY nh.n_name ORDER BY os.total_order_value DESC) AS rank
FROM NationHierarchy nh
LEFT JOIN OrderStats os ON nh.n_nationkey = os.c_nationkey
LEFT JOIN FilteredParts fp ON fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
WHERE os.total_order_value IS NOT NULL OR fp.total_availqty IS NOT NULL
ORDER BY nh.n_name, rank;
