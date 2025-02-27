WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), SupplierSummary AS (
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
), CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    ss.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent
FROM 
    RankedOrders ro
JOIN 
    SupplierSummary ss ON ro.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l WHERE l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey))
JOIN 
    CustomerSales cs ON ro.o_orderkey = cs.total_orders
WHERE 
    ro.revenue_rank <= 10
ORDER BY 
    ro.total_revenue DESC, cs.total_spent DESC;
