WITH RECURSIVE OrdersHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS order_level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, order_level + 1
    FROM orders o
    JOIN OrdersHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderkey < oh.o_orderkey AND o.o_orderstatus = 'O'
),
AggregatedSupplierCost AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100
    GROUP BY ps.s_suppkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ch.c_custkey,
    ch.c_name,
    ch.total_spent,
    ch.order_count,
    COALESCE(SC.total_cost, 0) AS supplier_total_cost,
    RANK() OVER (PARTITION BY ch.c_custkey ORDER BY ch.total_spent DESC) AS spending_rank
FROM 
    CustomerOrderSummary ch
LEFT JOIN 
    AggregatedSupplierCost SC ON SC.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey
        JOIN orders o ON li.l_orderkey = o.o_orderkey
        WHERE o.o_custkey = ch.c_custkey
        ORDER BY li.l_extendedprice DESC
        LIMIT 1
    )
WHERE 
    ch.total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerOrderSummary
    )
ORDER BY 
    ch.total_spent DESC
LIMIT 10;
