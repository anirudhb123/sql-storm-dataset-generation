WITH RECURSIVE SupplierCostCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost,
        ps.ps_availqty,
        1 AS level
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0

    UNION ALL

    SELECT 
        sc.s_suppkey,
        sc.s_name,
        sc.s_acctbal,
        ps.ps_supplycost,
        ps.ps_availqty,
        sc.level + 1
    FROM 
        SupplierCostCTE sc
    JOIN 
        partsupp ps ON sc.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0 AND sc.level < 5
),
AggregatedCosts AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        COUNT(*) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        *
    FROM 
        AggregatedCosts
    WHERE 
        rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT 
        c.c_name AS customer_name,
        MAX(case when ts.s_name IS NOT NULL then ts.total_supplycost else 0 end) AS max_supplier_cost,
        COALESCE(AVG(co.total_order_value), 0) AS avg_customer_order_value,
        STRING_AGG(ts.s_name, ', ') AS top_suppliers
    FROM 
        CustomerOrders co
    FULL OUTER JOIN 
        TopSuppliers ts ON co.c_custkey = ts.s_suppkey
    JOIN 
        customer c ON c.c_custkey = co.c_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    customer_name,
    max_supplier_cost,
    avg_customer_order_value,
    top_suppliers
FROM 
    FinalResults
WHERE 
    max_supplier_cost IS NOT NULL 
    OR avg_customer_order_value > 1000
ORDER BY 
    avg_customer_order_value DESC, max_supplier_cost DESC;
