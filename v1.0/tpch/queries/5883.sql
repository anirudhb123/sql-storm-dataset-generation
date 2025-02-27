
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), DiscountedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount) * (1 + l.l_tax)) AS net_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(co.total_spent) AS total_revenue,
    AVG(co.order_count) AS avg_orders_per_customer,
    SUM(dli.net_price) AS total_discounted_revenue,
    s.s_name AS top_supplier
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank = 1
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
JOIN 
    DiscountedLineItems dli ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = dli.l_orderkey)
GROUP BY 
    r.r_name, s.s_name
ORDER BY 
    total_revenue DESC;
