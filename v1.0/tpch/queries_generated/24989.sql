WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance'
            WHEN s.s_acctbal = 0 THEN 'Zero Balance'
            ELSE 'Positive Balance'
        END AS balance_status
    FROM supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
OrderRegions AS (
    SELECT 
        c.c_nationkey, 
        SUM(co.total_order_value) AS region_order_value
    FROM CustomerOrders co
    JOIN customer c ON co.o_custkey = c.c_custkey
    GROUP BY c.c_nationkey
)
SELECT 
    r.r_name, 
    COALESCE(SUM(or.region_order_value), 0) AS total_region_value,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(CASE WHEN h.total_value IS NOT NULL THEN h.total_value ELSE 0 END) AS avg_part_value
FROM region r
LEFT JOIN OrderRegions or ON r.r_regionkey = or.c_nationkey
LEFT JOIN RankedSuppliers rs ON rs.rnk <= 3
LEFT JOIN HighValueParts h ON h.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty > (SELECT AVG(pss.ps_availqty) FROM partsupp pss) AND ps.ps_supplycost < (SELECT AVG(pss.ps_supplycost) FROM partsupp pss)
)
GROUP BY r.r_regionkey, r.r_name
HAVING AVG(COALESCE(rs.s_acctbal, 0)) > 5000
ORDER BY total_region_value DESC, supplier_count DESC;
