WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
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
RecentOrders AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    hvc.c_name AS customer_name,
    COUNT(DISTINCT ro.l_orderkey) AS recent_order_count,
    COALESCE(SUM(ro.total_order_value), 0) AS recent_order_total,
    rs.s_name AS top_supplier,
    rs.s_acctbal AS top_supplier_balance
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentOrders ro ON hvc.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ro.l_orderkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.supplier_rank = 1
WHERE 
    hvc.total_spent IS NOT NULL
GROUP BY 
    hvc.c_name, rs.s_name, rs.s_acctbal
ORDER BY 
    recent_order_total DESC, customer_name ASC;
