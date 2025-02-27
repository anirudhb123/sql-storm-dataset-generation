WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rn <= 5
    GROUP BY r.r_name, rs.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
Combinations AS (
    SELECT 
        r.r_name,
        cs.c_custkey,
        cs.total_spent,
        COALESCE(ts.part_count, 0) AS part_count
    FROM CustomerOrders cs
    LEFT JOIN TopSuppliers ts ON cs.total_spent > 1000 AND ts.part_count > 0
    JOIN region r ON r.r_name IS NOT NULL
),
FinalSelection AS (
    SELECT 
        r_name,
        c_custkey,
        total_spent,
        part_count,
        CASE 
            WHEN total_spent IS NULL THEN 'NO ORDERS'
            WHEN total_spent < 500 THEN 'LOW SPENDER'
            ELSE 'HIGH SPENDER'
        END AS spending_category
    FROM Combinations
)

SELECT 
    f.r_name,
    f.c_custkey,
    f.total_spent,
    f.part_count,
    f.spending_category,
    (SELECT SUM(p.p_retailprice) 
     FROM part p 
     WHERE p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_name = f.r_name)))
     GROUP BY f.c_custkey) AS total_parts_value
FROM FinalSelection f
WHERE f.total_spent IS NOT NULL
ORDER BY f.r_name, f.total_spent DESC
LIMIT 100 OFFSET 10;
