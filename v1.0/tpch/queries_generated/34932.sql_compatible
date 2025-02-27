
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
),

PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name AS supplier_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),

AggregateSales AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    INNER JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)

SELECT 
    rh.r_name AS region_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_revenue,
    MAX(ads.total_spent) AS highest_spender,
    STRING_AGG(DISTINCT CONCAT(ps.p_name, ' from ', ps.supplier_name), '; ') AS parts_supplied
FROM 
    region rh
LEFT JOIN 
    nation n ON rh.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    PartSupplierDetails ps ON s.s_suppkey = ps.p_partkey
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey
LEFT JOIN 
    AggregateSales ads ON co.c_custkey = ads.c_custkey
WHERE 
    (co.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01' OR co.o_orderdate IS NULL)
    AND rh.r_name IS NOT NULL
GROUP BY 
    rh.r_name
ORDER BY 
    total_revenue DESC;
