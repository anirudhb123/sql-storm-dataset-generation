WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),

SupplierRevenue AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),

CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.lineitem_count,
    r.total_revenue,
    cs.c_name,
    cs.total_spent,
    cs.orders_count,
    sr.supplier_cost,
    sr.supplied_parts
FROM 
    RankedOrders r
JOIN 
    CustomerSummary cs ON r.o_orderkey = (
        SELECT MIN(o_orderkey)
        FROM orders
        WHERE o_custkey = cs.c_custkey
        AND o_orderstatus = 'O'
    )
LEFT JOIN 
    SupplierRevenue sr ON sr.supplier_cost > (
        SELECT AVG(supplier_cost) FROM SupplierRevenue
    )
WHERE 
    r.order_rank <= 5
ORDER BY 
    total_revenue DESC, 
    total_spent DESC;
