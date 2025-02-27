WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 3
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
PartAveragePrice AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
LineitemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count,
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name,
    s.s_name,
    p.p_name,
    grp.total_revenue,
    AVG(pa.avg_price) AS avg_part_price,
    SUM(sh.level) AS supplier_levels
FROM TopCustomers c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitemStats grp ON o.o_orderkey = grp.l_orderkey
LEFT JOIN partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX')
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
JOIN part p ON p.p_partkey = ps.ps_partkey
WHERE c.total_spent > 1000
GROUP BY c.c_name, s.s_name, p.p_name, grp.total_revenue
HAVING COUNT(DISTINCT ps.ps_partkey) > 3
ORDER BY grp.total_revenue DESC, AVG(pa.avg_price) ASC;
