WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank,
        CASE 
            WHEN SUM(ps.ps_availqty) IS NULL THEN 0
            ELSE SUM(ps.ps_availqty) 
        END AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
OrderStatistics AS (
    SELECT 
        o.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.total_order_value) AS avg_order_value
    FROM CustomerOrders o
    GROUP BY o.c_custkey
),
TopRegions AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, r.r_regionkey
    HAVING COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT 
    c.c_name,
    SUM(o.order_count) AS total_orders,
    MAX(o.avg_order_value) AS highest_avg_order_value,
    r.r_name,
    (SELECT COUNT(DISTINCT s.s_name) 
     FROM RankedSuppliers rs 
     WHERE rs.supply_rank <= 3) AS top_supplier_count,
    (SELECT COALESCE(SUM(total_avail_qty), 0) 
     FROM RankedSuppliers rs2
     WHERE rs2.s_supply_rank = 1) AS top_avail_qty
FROM OrderStatistics o
JOIN customer c ON c.c_custkey = o.c_custkey
LEFT JOIN TopRegions r ON r.n_nationkey = c.c_nationkey 
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
GROUP BY c.c_name, r.r_name
ORDER BY total_orders DESC, highest_avg_order_value DESC
LIMIT 10;
