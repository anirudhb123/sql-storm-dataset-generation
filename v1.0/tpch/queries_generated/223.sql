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
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_order_value,
        COALESCE(NULLIF(co.order_count, 0), 1) AS adjusted_order_count
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrders)
),
NationParts AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT p.p_partkey) AS parts_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    np.parts_count,
    np.total_supply_cost,
    hs.c_name AS high_value_customer,
    hs.total_order_value,
    hs.adjusted_order_count,
    ss.total_cost AS supplier_total_cost
FROM 
    NationParts np
LEFT JOIN 
    HighValueCustomers hs ON np.parts_count > 10
LEFT JOIN 
    SupplierSummary ss ON np.total_supply_cost > ss.total_cost
WHERE 
    np.parts_count > 5 OR hs.total_order_value IS NOT NULL
ORDER BY 
    np.total_supply_cost DESC, hs.total_order_value DESC;
