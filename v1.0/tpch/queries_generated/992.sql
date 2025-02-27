WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT 
        c.custkey,
        c.name,
        co.total_spent,
        co.order_count,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > 1000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY sp.avg_supply_cost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
    WHERE 
        sp.total_avail_qty > 50
)
SELECT 
    c.c_name AS customer_name,
    c.total_spent AS customer_spent,
    s.s_name AS supplier_name,
    sp.avg_supply_cost AS supplier_cost,
    COALESCE(c.order_count, 0) AS orders_count,
    COALESCE(s.rank, 0) AS supplier_rank
FROM 
    HighSpendingCustomers c
FULL OUTER JOIN 
    TopSuppliers s ON c.c_custkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey ORDER BY ps.ps_availqty DESC LIMIT 1)
WHERE 
    (c.order_count IS NULL OR s.rank IS NOT NULL)
ORDER BY 
    c.total_spent DESC, s.avg_supply_cost ASC;
