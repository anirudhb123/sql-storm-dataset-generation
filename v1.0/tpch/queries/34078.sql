WITH RECURSIVE CustOrderHierarchy AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, 1 AS order_level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'A'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, coh.order_level + 1
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustOrderHierarchy coh ON coh.o_orderkey < o.o_orderkey
    WHERE o.o_orderstatus = 'A'
),
SupplierStats AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey
),
CustomerTotalOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT DISTINCT
    c.c_custkey,
    c.c_name,
    cth.o_orderdate,
    cth.order_level,
    COALESCE(cto.total_spent, 0) AS total_spent,
    COALESCE(ss.total_cost, 0) AS total_cost,
    CASE 
        WHEN COALESCE(cto.total_spent, 0) > 1000 THEN 'High Spender'
        ELSE 'Regular'
    END AS customer_type
FROM CustOrderHierarchy cth
JOIN customer c ON cth.c_custkey = c.c_custkey
LEFT JOIN CustomerTotalOrders cto ON c.c_custkey = cto.c_custkey
LEFT JOIN SupplierStats ss ON ss.p_partkey = (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    WHERE li.l_orderkey = cth.o_orderkey 
    LIMIT 1
)
WHERE c.c_acctbal IS NOT NULL
  AND c.c_acctbal > 0
ORDER BY cth.order_level DESC, c.c_name;
