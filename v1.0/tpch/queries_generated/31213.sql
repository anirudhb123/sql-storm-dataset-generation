WITH RECURSIVE RankedSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY s_acctbal DESC) AS rank,
        s_nationkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
HighValueParts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(l.l_orderkey) AS items_ordered
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(rsp.total_value) AS avg_part_value,
    COALESCE(SUM(ro.total_spent), 0) AS total_spent_last_6_months,
    COUNT(sm.s_suppkey) AS supplier_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN RecentOrders ro ON ro.o_custkey = c.c_custkey
LEFT JOIN HighValueParts hvp ON hvp.ps_partkey IN (
    SELECT p.p_partkey 
    FROM part p 
    WHERE p.p_retailprice > 200
)
JOIN RankedSuppliers rsp ON rsp.s_nationkey = n.n_nationkey AND rsp.rank <= 5
GROUP BY n.n_name, r.r_name
ORDER BY total_spent_last_6_months DESC, unique_customers DESC;
