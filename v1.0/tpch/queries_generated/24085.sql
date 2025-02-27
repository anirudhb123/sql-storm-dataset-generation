WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS average_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(o.o_totalprice) > (
        SELECT AVG(o_sum)
        FROM (SELECT SUM(o_totalprice) AS o_sum
              FROM orders
              GROUP BY o_custkey) AS avg_orders
    )
),
FinalOutput AS (
    SELECT 
        t.n_name AS nation_name,
        p.p_name AS part_name,
        ps.s_name AS supplier_name,
        cs.order_count,
        ps.supplier_count,
        p.average_cost,
        COALESCE(ps.supplier_count, 0) AS null_supplier_handling
    FROM TopNations t
    JOIN PartStats p ON p.supplier_count > ALL (SELECT supplier_count FROM PartStats)
    LEFT JOIN RankedSuppliers ps ON ps.rn = 1
    LEFT JOIN CustomerOrders cs ON cs.c_custkey = p.p_partkey
    WHERE t.total_sales IS NOT NULL
)

SELECT DISTINCT 
    f.nation_name,
    f.part_name,
    f.supplier_name,
    CASE 
        WHEN f.order_count IS NULL THEN 'No Orders'
        ELSE CAST(f.order_count AS VARCHAR)
    END AS formatted_order_count,
    f.average_cost
FROM FinalOutput f
ORDER BY f.nation_name, f.part_name;
