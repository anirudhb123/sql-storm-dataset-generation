WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_region
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_suppkey,
        s.s_name,
        s.total_supply_cost
    FROM SupplierStats s
    WHERE s.rank_in_region <= 3
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        ts.s_name AS top_supplier,
        cs.order_count,
        cs.total_spent,
        ts.total_supply_cost
    FROM CustomerOrderSummary cs
    LEFT JOIN TopSuppliers ts ON cs.order_count > 0
),
AggregatedData AS (
    SELECT 
        f.c_custkey,
        f.c_name,
        AVG(f.total_spent) AS avg_spending,
        COUNT(DISTINCT f.top_supplier) AS distinct_suppliers
    FROM FinalReport f
    GROUP BY f.c_custkey, f.c_name
)

SELECT 
    a.c_custkey,
    a.c_name,
    a.avg_spending,
    COALESCE(a.distinct_suppliers, 0) AS unique_suppliers,
    CASE 
        WHEN a.avg_spending > 500 THEN 'High Value'
        WHEN a.avg_spending BETWEEN 200 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM AggregatedData a
ORDER BY a.avg_spending DESC;

