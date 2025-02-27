WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(ps.ps_partkey) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND
        c.c_mktsegment IN (SELECT DISTINCT c_mktsegment FROM customer WHERE c_acctbal > 1000)
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        rs.part_count,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn = 1
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent
    FROM 
        FilteredCustomers c 
    WHERE 
        c.total_spent > 5000
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    s.total_supply_cost AS supplier_cost,
    CASE 
        WHEN s.total_supply_cost > (SELECT AVG(total_supply_cost) FROM TopSuppliers) THEN 'Above Average Supplier Cost' 
        ELSE 'Below Average Supplier Cost' 
    END AS supplier_cost_comparison,
    COALESCE(o.o_orderkey, 'No Orders') AS order_key,
    DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY s.total_supply_cost DESC) AS rank_by_supplier_cost
FROM 
    HighSpendingCustomers c
LEFT JOIN 
    TopSuppliers s ON c.c_custkey MOD 10 = s.s_suppkey % 10
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey AND o.o_orderdate BETWEEN DATEADD(MONTH, -12, GETDATE()) AND GETDATE()
WHERE 
    (c.c_custkey IS NOT NULL OR s.s_suppkey IS NULL)
    AND (s.part_count IS NOT NULL OR c.total_spent IS NULL)
ORDER BY 
    c.c_name ASC, s.total_supply_cost DESC;
