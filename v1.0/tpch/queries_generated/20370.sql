WITH SupplyCostCTE AS (
    SELECT ps_partkey, 
           ps_suppkey, 
           ps_availqty, 
           ps_supplycost, 
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) as SupplyRank
    FROM partsupp
    WHERE ps_availqty > 0
), 
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent 
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
NationRegion AS (
    SELECT n.n_nationkey, 
           n.n_name,
           r.r_name
    FROM nation n
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey
), 
FilteredLineItems AS (
    SELECT l.l_orderkey, 
           l.l_partkey, 
           l.l_quantity, 
           l.l_discount, 
           l.l_tax, 
           CASE 
               WHEN l.l_returnflag = 'Y' THEN 'Returned'
               ELSE 'Not Returned' 
           END AS return_status
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
)

SELECT n.n_name, 
       SUM(CASE WHEN li.return_status = 'Returned' THEN li.l_quantity ELSE 0 END) AS total_returned_qty,
       SUM(CASE WHEN li.return_status = 'Not Returned' THEN li.l_quantity ELSE 0 END) AS total_shipped_qty,
       AVG(c.total_spent) AS avg_customer_spent,
       STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts
FROM SupplyCostCTE s
JOIN FilteredLineItems li ON s.ps_partkey = li.l_partkey
JOIN CustomerOrders c ON c.c_custkey IN (
    SELECT DISTINCT o.o_custkey 
    FROM orders o 
    JOIN lineitem li2 ON o.o_orderkey = li2.l_orderkey
    WHERE li2.l_discount > 0.1
)
JOIN nation n ON n.n_nationkey = (
    SELECT s.s_nationkey 
    FROM supplier s 
    WHERE s.s_suppkey = s.ps_suppkey
)
LEFT JOIN part p ON p.p_partkey = s.ps_partkey
GROUP BY n.n_name
HAVING COUNT(li.l_orderkey) > 10
ORDER BY total_returned_qty DESC
LIMIT 5;
