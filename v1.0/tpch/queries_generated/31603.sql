WITH RECURSIVE RevenueCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(r.total_revenue, 0) AS total_revenue
    FROM customer c
    LEFT JOIN RevenueCTE r ON c.c_custkey = r.c_custkey
    WHERE r.rn <= 5 OR r.rn IS NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
NationCounts AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
FinalResult AS (
    SELECT 
        tc.c_name AS Customer,
        hp.p_name AS High_Value_Part,
        nc.n_name AS Nation,
        tc.total_revenue AS Customer_Revenue,
        hp.total_supply_value AS Part_Supply_Value,
        nc.supplier_count AS Nation_Supplier_Count
    FROM TopCustomers tc
    JOIN HighValueParts hp ON tc.total_revenue > 5000 -- Only customers with revenue above 5000
    JOIN NationCounts nc ON tc.c_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = nc.n_nationkey
    )
)
SELECT 
    Customer,
    High_Value_Part,
    Nation,
    Customer_Revenue,
    Part_Supply_Value,
    Nation_Supplier_Count
FROM FinalResult
ORDER BY Customer_Revenue DESC, Part_Supply_Value DESC
LIMIT 10;
