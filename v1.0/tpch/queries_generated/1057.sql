WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.s_acctbal) AS average_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 0
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_income,
        COUNT(l.l_linenumber) AS line_count,
        AVG(l.l_quantity) AS avg_quantity,
        MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    cs.c_name,
    cs.total_spent,
    ss.s_name,
    ss.total_supply_cost,
    la.total_income,
    la.line_count,
    la.avg_quantity
FROM CustomerOrderStats cs
JOIN SupplierStats ss ON ss.part_count > 5
LEFT JOIN LineItemAnalysis la ON la.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = cs.c_custkey AND o.o_orderstatus = 'O'
)
WHERE cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC, ss.total_supply_cost ASC
LIMIT 100;
