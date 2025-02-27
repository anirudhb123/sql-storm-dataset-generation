WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, rs.level + 1
    FROM supplier s
    JOIN RecursiveSupplier rs ON s.s_nationkey = rs.s_nationkey
    WHERE rs.level < 3
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice = (SELECT MAX(p1.p_retailprice) FROM part p1 WHERE p1.p_size < 100)
),
SupplierPartStats AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_availqty, 
           AVG(ps.ps_supplycost) AS avg_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS row_num
    FROM partsupp ps
    JOIN HighValueParts h ON ps.ps_partkey = h.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey,
           COUNT(DISTINCT o.o_orderkey) AS orders_count,
           SUM(o.o_totalprice) AS total_spent,
           (CASE WHEN SUM(o.o_totalprice) IS NULL THEN 'No Orders' ELSE 'Has Orders' END) AS order_status
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FinalStats AS (
    SELECT 
        cp.cust_key,
        cp.orders_count,
        cp.total_spent,
        CASE 
            WHEN rs.s_name IS NOT NULL THEN rs.s_name 
            ELSE 'Unknown Supplier' 
        END AS top_supplier,
        ps.part_key,
        ps.total_availqty,
        ps.avg_supplycost
    FROM CustomerOrderStats cp
    LEFT JOIN SupplierPartStats ps ON cp.c_custkey = ps.ps_suppkey
    LEFT JOIN RecursiveSupplier rs ON ps.ps_suppkey = rs.s_suppkey
)
SELECT 
    f.cust_key,
    f.orders_count,
    f.total_spent,
    COALESCE(NULLIF(f.top_supplier, 'Unknown Supplier'), 'Error: No Supplier') AS resolved_supplier,
    f.part_key,
    f.total_availqty,
    ROUND(f.avg_supplycost, 2) AS formatted_supplycost
FROM FinalStats f
WHERE f.orders_count > 0 OR (f.orders_count = 0 AND f.total_spent IS NULL)
ORDER BY f.total_spent DESC NULLS LAST, f.part_key ASC
FETCH FIRST 10 ROWS ONLY;
