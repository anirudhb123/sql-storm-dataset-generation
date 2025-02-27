WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
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
LineItemInfo AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' 
        AND l.l_shipdate <= '2023-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COALESCE(SUM(sd.total_supply_cost), 0) AS total_supply_cost_for_region,
    COALESCE(SUM(co.total_spent), 0) AS total_spent_by_customers,
    COUNT(DISTINCT li.l_orderkey) AS total_orders_in_2023,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers_active
FROM 
    nation n
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
LEFT JOIN 
    CustomerOrders co ON n.n_nationkey = co.c_nationkey
LEFT JOIN 
    orders o ON co.c_custkey = o.o_custkey
LEFT JOIN 
    LineItemInfo li ON o.o_orderkey = li.l_orderkey
GROUP BY 
    n.n_name
ORDER BY 
    total_supply_cost_for_region DESC, total_spent_by_customers DESC;
