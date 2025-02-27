WITH RECURSIVE Region_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name = 'FRANCE'
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN Region_Suppliers rs ON rs.s_suppkey <> s.s_suppkey
    WHERE rs.n_name = 'GERMANY'
),
Part_Supplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
Customer_Income AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
High_Value_Customers AS (
    SELECT c.c_custkey, c.c_name
    FROM customer c
    JOIN Customer_Income ci ON c.c_custkey = ci.c_custkey
    WHERE ci.total_spent > (
        SELECT AVG(total_spent) 
        FROM Customer_Income
    )
),
Ranked_Orders AS (
    SELECT o.o_orderkey, o.o_custkey, RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT DISTINCT hs.s_name, hs.n_name, 
       p.p_name, ps.total_cost, 
       c.c_name AS high_value_customer, 
       ROW_NUMBER() OVER (PARTITION BY hs.n_name ORDER BY ps.total_cost DESC) AS rank
FROM Part_Supplier ps
JOIN Region_Suppliers hs ON ps.p_partkey IN (
    SELECT ps_inner.ps_partkey
    FROM partsupp ps_inner
    WHERE ps_inner.ps_supplycost < (
        SELECT AVG(ps_inner_sub.ps_supplycost)
        FROM partsupp ps_inner_sub
        WHERE ps_inner_sub.ps_availqty IS NOT NULL
    )
)
LEFT OUTER JOIN High_Value_Customers c ON hs.s_suppkey = c.c_custkey
WHERE ps.total_cost IS NOT NULL AND hs.n_name IS NOT NULL
ORDER BY hs.n_name, ps.total_cost DESC;
