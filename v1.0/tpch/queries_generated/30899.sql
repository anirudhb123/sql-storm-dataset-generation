WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate AND o.o_orderstatus = 'O'
),
AggregatedOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(oh.o_totalprice) AS total_spent,
        COUNT(oh.o_orderkey) AS order_count,
        MAX(oh.o_orderdate) AS last_order_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(oh.o_totalprice) DESC) AS rnk
    FROM customer c
    JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        IFNULL(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, ao.total_spent, ao.order_count
    FROM AggregatedOrders ao
    JOIN customer c ON ao.c_custkey = c.c_custkey
    WHERE ao.rnk <= 10
)
SELECT 
    tc.c_name,
    COALESCE(spd.s_name, 'No Supplier') as supplier_name,
    SUM(spd.total_supply_value) AS total_supplier_value,
    AVG(tc.total_spent) AS avg_spent_per_customer,
    COUNT(DISTINCT spd.p_partkey) AS unique_parts_provided
FROM TopCustomers tc
LEFT JOIN SupplierPartDetails spd ON tc.c_custkey = spd.s_suppkey
GROUP BY tc.c_name, spd.s_name
ORDER BY avg_spent_per_customer DESC, total_supplier_value DESC
LIMIT 20;
