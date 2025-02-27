WITH SupplierTotal AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_supply_cost,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierTotal s
),
ProductSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(co.order_count, 0) AS order_count,
    ps.total_quantity_sold,
    ps.avg_price,
    ss.supply_rank
FROM 
    customer c
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    ProductSummary ps ON ps.total_quantity_sold IS NOT NULL
LEFT JOIN 
    RankedSuppliers ss ON ss.supply_rank <= 10
WHERE 
    co.order_count BETWEEN 1 AND 10
    AND ss.total_supply_cost IS NOT NULL
ORDER BY 
    co.total_spent DESC, ps.avg_price ASC;
