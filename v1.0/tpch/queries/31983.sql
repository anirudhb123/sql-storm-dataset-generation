WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 5000
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > 1000
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 20.00
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT 
    DISTINCT p.p_name AS part_name,
    s.s_name AS supplier_name,
    r.n_name AS nation_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    coalesce(coc.order_count, 0) AS customer_order_count,
    sh.level AS supplier_level
FROM 
    lineitem l
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation r ON s.s_nationkey = r.n_nationkey
LEFT JOIN 
    CustomerOrderCount coc ON coc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = r.n_nationkey AND c.c_acctbal > 0 ORDER BY c.c_acctbal DESC LIMIT 1)
JOIN 
    SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, r.n_name, coc.order_count, sh.level
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;