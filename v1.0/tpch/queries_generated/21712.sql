WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s1.s_acctbal) 
        FROM supplier s1 
        WHERE s1.s_nationkey = s.s_nationkey
    )
), HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(CASE WHEN ps.ps_supplycost < 10 THEN 1 ELSE 0 END) AS below_ten_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 20.00
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) > 100
), OrdersWithLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        SUM(l.l_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
), CombinedData AS (
    SELECT 
        r.r_name,
        COALESCE(SU.s_name, 'No Supplier') AS supplier_name,
        COUNT(DISTINCT H.p_partkey) AS high_value_parts_count,
        SUM(O.total_price) AS total_order_value
    FROM region r
    LEFT JOIN RankedSuppliers SU ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = SU.l_suppkey ORDER BY n.n_name LIMIT 1)
    LEFT JOIN HighValueParts H ON H.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost BETWEEN 5 AND 15)
    LEFT JOIN OrdersWithLineItems O ON SU.s_suppkey = O.o_custkey
    GROUP BY r.r_name, supplier_name
)
SELECT 
    r.r_name,
    SUM(CASE WHEN cd.high_value_parts_count > 0 THEN cd.high_value_parts_count ELSE NULL END) AS total_high_value_parts,
    AVG(cd.total_order_value) AS average_order_value
FROM CombinedData cd
JOIN region r ON cd.r_name = r.r_name
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(cd.total_high_value_parts) > 1
ORDER BY r.r_name DESC;
