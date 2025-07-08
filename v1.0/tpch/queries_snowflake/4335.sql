
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), OrdersSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders,
        COUNT(DISTINCT l.l_orderkey) AS unique_lines
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
), RegionsWithComments AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count,
        LISTAGG(n.n_comment, '; ') AS combined_nation_comments
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    rs.s_name,
    os.c_name,
    os.total_order_value,
    os.total_orders,
    rs.total_supply_cost,
    rwc.nation_count,
    rwc.combined_nation_comments
FROM RankedSuppliers rs
JOIN OrdersSummary os ON rs.rank <= 3
LEFT JOIN RegionsWithComments rwc ON rs.s_suppkey = os.c_custkey
WHERE os.total_order_value > (SELECT AVG(total_order_value) FROM OrdersSummary)
ORDER BY rs.total_supply_cost DESC, os.total_orders DESC
LIMIT 10;
