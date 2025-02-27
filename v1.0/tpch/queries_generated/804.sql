WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
), 
SupplierCosts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
)

SELECT 
    r.r_name,
    p.p_name,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_number,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_category,
    s.total_supply_cost
FROM 
    lineitem l
JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierCosts s ON p.p_partkey = s.ps_partkey
WHERE 
    l.l_shipdate BETWEEN o.o_orderdate AND o.o_orderdate + INTERVAL '30 days'
GROUP BY 
    r.r_name, p.p_name, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, s.total_supply_cost
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    r.r_name, o.o_orderdate DESC;
