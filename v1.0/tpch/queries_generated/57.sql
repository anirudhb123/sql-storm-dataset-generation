WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
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
        s.s_suppkey, 
        s.s_name
    FROM 
        SupplierStats s
    WHERE 
        s.rn <= 3
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY co.order_count DESC, co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    ts.s_suppkey,
    ts.s_name,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    COALESCE(NULLIF(tc.total_spent, 0), 'Not Applicable') AS total_spent_status
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    FrequentCustomers tc ON ts.s_suppkey = (SELECT MIN(ps.ps_suppkey) FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_suppkey = ts.s_suppkey)
LEFT JOIN 
    SupplierStats ss ON ts.s_suppkey = ss.s_suppkey
WHERE 
    (tc.total_spent IS NOT NULL OR ss.part_count > 0)
ORDER BY 
    tc.c_custkey, ts.s_suppkey;
