WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey, s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
NationInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        r.n_name,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        NationInfo r ON rs.s_nationkey = r.n_nationkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    o.o_orderkey,
    c.c_name,
    t.n_name AS supplier_nation,
    t.s_name AS supplier_name,
    o.order_value,
    CASE 
        WHEN o.order_value > 5000 THEN 'High Value'
        WHEN o.order_value BETWEEN 2500 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    RecentOrders o
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    TopSuppliers t ON t.total_cost > o.order_value
WHERE 
    c.c_acctbal IS NOT NULL 
    AND c.c_mktsegment NOT LIKE 'AUTOMOBILE'
ORDER BY 
    o.order_value DESC, 
    c.c_name ASC;
