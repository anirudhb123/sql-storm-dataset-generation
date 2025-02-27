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
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
),
SupplierOrderDetails AS (
    SELECT 
        s.s_name,
        COUNT(l.l_orderkey) AS line_count,
        AVG(l.l_quantity) AS avg_quantity,
        MAX(l.l_extendedprice) AS max_price
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    SUM(so.line_count) AS total_lines,
    AVG(so.avg_quantity) AS average_quantity,
    s.total_supply_cost
FROM 
    TopRegions r
LEFT JOIN 
    CustomerOrders c ON c.total_spent > 50000
LEFT JOIN 
    SupplierOrderDetails so ON so.line_count > 10
LEFT JOIN 
    RankedSuppliers s ON s.rank = 1
GROUP BY 
    r.r_name, s.total_supply_cost
ORDER BY 
    total_lines DESC, average_quantity ASC
LIMIT 100;
