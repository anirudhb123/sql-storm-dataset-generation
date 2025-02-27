WITH CTE_Customer_Orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000 AND c.c_name NOT LIKE 'A%'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
CTE_Low_Avg_Supplier AS (
    SELECT 
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
CTE_Orders_With_Rank AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
)
SELECT 
    c.c_name,
    o.order_rank,
    COALESCE(s.avg_supplycost, 0) AS avg_supplier_cost,
    CASE 
        WHEN o.total_orders > 10 THEN 'High Volume'
        WHEN o.total_orders BETWEEN 5 AND 10 THEN 'Medium Volume'
        ELSE 'Low Volume' 
    END AS volume_category,
    CONCAT('Customer ', c.c_name, ' has spent a total of ', TO_CHAR(c.total_spent, 'FM999,999,999.00'))
FROM CTE_Customer_Orders c
FULL OUTER JOIN CTE_Orders_With_Rank o ON c.c_custkey = o.o_custkey
LEFT JOIN CTE_Low_Avg_Supplier s ON s.ps_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2
        )
    )
    ORDER BY ps.ps_supplycost ASC
    FETCH FIRST 1 ROW ONLY
)
WHERE o.o_orderdate IS NOT NULL
ORDER BY c.c_name, o.order_rank;
