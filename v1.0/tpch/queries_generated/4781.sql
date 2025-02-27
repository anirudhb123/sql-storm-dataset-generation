WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_within_nation
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
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_shipdate,
        l.l_returnflag,
        l.l_linestatus,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_number
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
)
SELECT 
    r.r_name,
    SUM(ld.l_extendedprice * (1 - ld.l_discount)) AS total_revenue,
    COUNT(DISTINCT co.c_custkey) AS unique_customers,
    MAX(rs.total_supply_cost) AS max_supply_cost,
    MIN(CASE WHEN rs.rank_within_nation = 1 THEN rs.total_supply_cost ELSE NULL END) AS min_top_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    LineItemDetails ld ON s.s_suppkey = ld.l_partkey
LEFT JOIN 
    CustomerOrders co ON co.total_orders > 0
GROUP BY 
    r.r_name
HAVING 
    total_revenue > 1000000
ORDER BY 
    total_revenue DESC;
