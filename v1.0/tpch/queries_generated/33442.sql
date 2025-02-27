WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01'
    
    UNION ALL

    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.o_orderdate < o.o_orderdate
    WHERE o.o_orderdate < CURRENT_DATE()
),
SupplierSales AS (
    SELECT ps.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY ps.s_suppkey
),
SalesRanking AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales,
           RANK() OVER (ORDER BY ss.total_sales DESC) AS rank_sales
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT c.c_name, SUM(co.o_totalprice) AS total_customer_spending, 
       sr.rank_sales, sr.s_name AS top_supplier
FROM CustomerOrders co
JOIN SalesRanking sr ON sr.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey IN (
        SELECT co.o_orderkey FROM CustomerOrders co WHERE co.c_custkey = co.c_custkey
    )
    GROUP BY ps.ps_suppkey
    ORDER BY SUM(l.l_extendedprice) DESC
    LIMIT 1
)
JOIN customer c ON c.c_custkey = co.c_custkey
GROUP BY c.c_name, sr.rank_sales, sr.s_name
HAVING SUM(co.o_totalprice) > 1000
ORDER BY total_customer_spending DESC;
