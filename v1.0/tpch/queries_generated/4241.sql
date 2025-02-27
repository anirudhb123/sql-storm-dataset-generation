WITH SupplierStats AS (
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartPopularity AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY ss.total_cost DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > (
            SELECT AVG(total_spent) FROM CustomerOrders
        )
)
SELECT 
    p.p_name,
    pp.total_quantity_sold,
    CASE 
        WHEN rs.supplier_rank <= 5 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_status,
    hc.customer_rank
FROM 
    PartPopularity pp
LEFT JOIN 
    RankedSuppliers rs ON pp.total_quantity_sold > 100
FULL OUTER JOIN 
    HighValueCustomers hc ON hc.customer_rank IS NOT NULL
WHERE 
    pp.total_quantity_sold IS NOT NULL
ORDER BY 
    pp.total_quantity_sold DESC, hc.customer_rank;
