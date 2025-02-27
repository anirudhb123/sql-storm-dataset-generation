WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, oh.o_totalprice, level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate AND o.o_orderstatus = 'O'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT c.*, cs.total_spent
    FROM customer c
    JOIN CustomerOrders cs ON c.c_custkey = cs.c_custkey
    WHERE cs.spending_rank <= 5
),
OrderLineData AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        MAX(l.l_shipdate) AS latest_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT
    c.c_name AS customer_name,
    cs.order_count,
    cs.total_spent,
    COALESCE(ss.avg_supply_cost, 0) AS average_supply_cost,
    COALESCE(ols.total_line_price, 0) AS total_order_value,
    ols.latest_ship_date,
    RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
FROM TopCustomers c
LEFT JOIN SupplierStats ss ON ss.avg_supply_cost = (
    SELECT MIN(a.avg_supply_cost) 
    FROM SupplierStats a 
    WHERE a.total_available > 0
)
LEFT JOIN OrderLineData ols ON ols.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey = c.c_custkey
)
ORDER BY cs.total_spent DESC, c.c_name;
