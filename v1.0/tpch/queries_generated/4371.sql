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
        o.o_orderdate >= DATE '2022-01-01'
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    sd.s_name AS supplier_name,
    cp.customer_total_spent,
    CASE 
        WHEN r.revenue_rank <= 10 THEN 'Top Revenue Order'
        ELSE 'Regular Order'
    END AS order_rank,
    COALESCE(CASE 
        WHEN cp.customer_total_spent IS NULL THEN 'No Purchases'
        ELSE cp.c_name
    END, '-') AS customer_name
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierDetails sd ON r.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey = r.o_orderkey
    )
LEFT JOIN 
    CustomerPurchases cp ON r.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        WHERE 
            o.o_custkey = cp.c_custkey
    )
ORDER BY 
    r.total_revenue DESC, r.o_orderdate;
