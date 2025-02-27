WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS order_level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        co.order_level + 1
    FROM CustomerOrders co
    JOIN orders o ON co.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
),
SupplierHighlights AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
RegionalStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        AVG(s.s_acctbal) AS average_balance
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    co.order_level,
    rs.region_name,
    rs.supplier_count,
    rs.part_count,
    rs.average_balance,
    sh.total_supply_value,
    sh.part_count AS supplier_part_count
FROM CustomerOrders co
JOIN RegionalStats rs ON co.o_orderkey % 10 = rs.n_nationkey  
LEFT JOIN SupplierHighlights sh ON sh.total_supply_value IN (SELECT MAX(total_supply_value) FROM SupplierHighlights)
WHERE co.o_totalprice > 200 AND rs.average_balance IS NOT NULL
ORDER BY co.o_orderdate DESC, rs.average_balance DESC
LIMIT 100;