WITH RECURSIVE CTE_Supplier_Totals AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CTE_Customer_Orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
CTE_LineItem_Summary AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS final_price,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    s.s_name,
    c.c_name,
    coalesce(o.order_count, 0) AS order_count,
    coalesce(c.total_spent, 0) AS total_spent,
    c.avg_order_value,
    p.p_name,
    p.p_retailprice,
    COALESCE(lt.final_price, 0) AS final_price,
    COALESCE(st.total_cost, 0) AS total_supply_cost
FROM CTE_Supplier_Totals st
FULL OUTER JOIN CTE_Customer_Orders c ON c.c_custkey = (
    SELECT c1.c_custkey 
    FROM CTE_Customer_Orders c1 
    WHERE c1.order_count = (SELECT MAX(order_count) FROM CTE_Customer_Orders)
)
LEFT JOIN lineitem l ON l.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'O'
)
JOIN part p ON p.p_partkey = l.l_partkey
LEFT JOIN CTE_LineItem_Summary lt ON l.l_orderkey = lt.l_orderkey
WHERE st.rank = 1
ORDER BY c.total_spent DESC, st.total_cost DESC;
