WITH RECURSIVE ProductHierarchy AS (
    SELECT 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, 
        ps.ps_availqty, ps.ps_supplycost, ps.ps_comment,
        1 AS level
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT 
        ph.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, 
        ps.ps_availqty, ps.ps_supplycost, ps.ps_comment,
        ph.level + 1
    FROM ProductHierarchy ph
    JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ph.level < 5
),

TotalOrderValue AS (
    SELECT 
        o.o_orderkey, o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),

SupplierInfo AS (
    SELECT 
        s.s_suppkey, s.s_name,
        COUNT(DISTINCT ph.p_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN ProductHierarchy ph ON ps.ps_partkey = ph.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),

OrderRanks AS (
    SELECT 
        o.o_orderkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
)

SELECT 
    r.r_name,
    si.s_name,
    SUM(si.total_supply_cost) AS total_supply_cost,
    COUNT(DISTINCT oi.o_orderkey) AS order_count,
    AVG(tv.total_value) AS average_order_value,
    MAX(oi.order_rank) AS highest_order_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier si ON n.n_nationkey = si.s_nationkey
LEFT JOIN SupplierInfo si ON si.s_suppkey = si.s_suppkey
LEFT JOIN TotalOrderValue tv ON tv.total_value IS NOT NULL
LEFT JOIN OrderRanks oi ON oi.o_orderkey IS NOT NULL
GROUP BY r.r_name, si.s_name
HAVING COUNT(DISTINCT si.p_partkey) > 5 AND AVG(tv.total_value) IS NOT NULL
ORDER BY r.r_name, total_supply_cost DESC;
