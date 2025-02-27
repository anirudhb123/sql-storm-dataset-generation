WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedSuppliers AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS rank_cost,
        RANK() OVER (ORDER BY part_count DESC) AS rank_parts
    FROM 
        SupplierStats s
),
RecentOrders AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_extendedprice,
        l.l_discount,
        l.o_orderdate,
        DATEDIFF(CURRENT_DATE, l.o_orderdate) AS days_since_order
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
)
SELECT 
    r.s_name AS supplier_name,
    rs.rank_cost,
    rs.rank_parts,
    COALESCE(c.c_name, 'N/A') AS customer_name,
    COALESCE(c.order_count, 0) AS customer_order_count,
    COALESCE(c.total_spent, 0.00) AS total_spent,
    COALESCE(SUM(ri.l_extendedprice * (1 - ri.l_discount)), 0.00) AS total_revenue,
    COUNT(DISTINCT ri.l_orderkey) AS unique_orders_count
FROM 
    RankedSuppliers rs
LEFT JOIN 
    RecentOrders ri ON rs.s_suppkey = ri.l_suppkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey = ri.l_orderkey
GROUP BY 
    supplier_name, rs.rank_cost, rs.rank_parts, customer_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC, supplier_name;
