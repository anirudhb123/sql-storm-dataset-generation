WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate < DATEADD(day, -30, oh.o_orderdate)
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT l.l_orderkey, 
           SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice ELSE 0 END) AS discounted_sales,
           AVG(l.l_quantity) AS avg_quantity,
           COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
)

SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(li.discounted_sales), 0) AS total_discounted_sales,
    COALESCE(tp.total_spent, 0) AS top_customer_spent,
    COALESCE(sp.total_cost, 0) AS supplier_total_cost
FROM part p
LEFT JOIN LineItemStats li ON p.p_partkey = li.l_orderkey
LEFT JOIN TopCustomers tp ON tp.c_custkey = li.l_orderkey
LEFT JOIN SupplierPerformance sp ON sp.s_suppkey = (SELECT ps.ps_suppkey 
                                                      FROM partsupp ps 
                                                      WHERE ps.ps_partkey = p.p_partkey 
                                                      ORDER BY ps.ps_supplycost DESC 
                                                      LIMIT 1)
GROUP BY p.p_partkey, p.p_name
HAVING total_discounted_sales > 10000 
   OR top_customer_spent > 5000 
ORDER BY total_discounted_sales DESC, supplier_total_cost DESC;
