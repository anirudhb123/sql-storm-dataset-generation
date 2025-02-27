WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS lvl
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
  
    UNION ALL
  
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.lvl + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = 
        (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'N%')
    WHERE c.c_acctbal < ch.c_acctbal AND c.c_custkey <> ch.c_custkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > (SELECT AVG(ps_availqty) FROM partsupp)
),
FilteredLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice) IS NOT NULL
)
SELECT DISTINCT
    ch.c_name,
    ts.s_name,
    COUNT(DISTINCT li.l_orderkey) AS orders_count,
    SUM(li.total_sales) AS total_sales,
    ARRAY_AGG(DISTINCT li.l_shipmode) AS ship_modes,
    CASE 
        WHEN AVG(ch.c_acctbal) >= 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value
FROM CustomerHierarchy ch
LEFT JOIN TopSuppliers ts ON ts.total_cost > (SELECT MIN(total_cost) FROM TopSuppliers)
LEFT JOIN FilteredLineItems li ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ch.c_custkey)
WHERE ts.s_name LIKE '%Corp%' OR ts.s_name IS NULL
GROUP BY ch.c_name, ts.s_name
ORDER BY customer_value DESC, orders_count DESC
LIMIT 50 OFFSET 10;
