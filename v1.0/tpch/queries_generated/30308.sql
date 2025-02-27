WITH RECURSIVE Supplier_CTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier s
    JOIN Supplier_CTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE s.s_acctbal > 0
),
Part_Supplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
Customer_Orders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
Max_Supply_Cost AS (
    SELECT MAX(total_supply_cost) AS max_cost
    FROM Part_Supplier
)
SELECT cs.cust_key, cs.total_order_value, ps.p_name,
       CASE 
           WHEN cs.total_order_value IS NULL THEN 'No Orders' 
           ELSE 'Has Orders' 
       END AS order_status,
       CASE 
           WHEN ps.total_supply_cost > (SELECT max_cost FROM Max_Supply_Cost) 
           THEN 'Above Average'
           ELSE 'Average or Below'
       END AS supply_cost_status
FROM Customer_Orders cs
FULL OUTER JOIN Part_Supplier ps ON cs.c_custkey = ps.p_partkey
WHERE (cs.order_rank = 1 OR ps.total_supply_cost IS NOT NULL)
ORDER BY cs.total_order_value DESC, ps.total_supply_cost;
