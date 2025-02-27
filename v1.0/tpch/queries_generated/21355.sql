WITH RECURSIVE SupplyCostCTE AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, 1 AS depth
    FROM partsupp
    WHERE ps_supplycost IS NOT NULL
    UNION ALL
    SELECT p.ps_partkey, p.ps_suppkey, p.ps_availqty, p.ps_supplycost, sc.depth + 1
    FROM partsupp p
    INNER JOIN SupplyCostCTE sc ON p.ps_partkey = sc.ps_partkey
    WHERE p.ps_supplycost < sc.ps_supplycost AND sc.depth < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    GROUP BY c.c_custkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000.00
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice END) AS avg_fulfilled_order_value,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueSuppliers hvs ON hvs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
WHERE 
    r.r_name LIKE 'Eu%' AND
    (c.c_mktsegment IS NULL OR c.c_mktsegment = 'BUILDING') AND 
    (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 AND 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC, 
    unique_suppliers ASC
LIMIT 100;
