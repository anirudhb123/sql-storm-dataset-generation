WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name, 
        ss.total_cost, 
        RANK() OVER (ORDER BY ss.total_cost DESC) AS supplier_rank
    FROM 
        SupplierSummary ss
),
HighSpendingCustomers AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        co.total_spent, 
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
)
SELECT 
    ns.n_name AS nation_name,
    ss.s_name AS supplier_name,
    co.c_name AS customer_name,
    CASE 
        WHEN ss.total_cost IS NULL THEN 'No Supply'
        ELSE CONCAT('Total Cost: $', FORMAT(ss.total_cost, 2))
    END AS supplier_summary,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE CONCAT('Total Spent: $', FORMAT(co.total_spent, 2))
    END AS customer_summary
FROM 
    nation ns
LEFT JOIN 
    supplier ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN 
    customer co ON ns.n_nationkey = co.c_nationkey
WHERE 
    ss.s_suppkey IN (SELECT s.s_suppkey FROM TopSuppliers s WHERE s.supplier_rank <= 5)
    AND co.c_custkey IN (SELECT c.c_custkey FROM HighSpendingCustomers c WHERE c.customer_rank <= 5)
ORDER BY 
    ns.n_name, ss.s_name, co.c_name;
