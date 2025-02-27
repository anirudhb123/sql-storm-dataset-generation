WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_custkey,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM 
        orders o
),
SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supply_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
NullHandling AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(NULLIF(SUM(ps.ps_availqty), 0), 0) AS total_available_qty,
        CASE 
            WHEN SUM(ps.ps_supplycost) IS NULL THEN 'No Supply Cost'
            ELSE CAST(SUM(ps.ps_supplycost) AS VARCHAR)
        END AS supply_cost_info
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    h.c_name AS high_value_customer,
    so.total_supply_value,
    r.total_available_qty,
    r.supply_cost_info
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    HighValueCustomers h ON n.n_nationkey = h.c_custkey
LEFT JOIN 
    SupplierOrders so ON so.order_count > 5
JOIN 
    NullHandling r ON r.total_available_qty > 0
WHERE 
    h.total_spent IS NOT NULL OR r.supply_cost_info = 'No Supply Cost'
ORDER BY 
    r.r_name, so.total_supply_value DESC, h.high_value_customer;
