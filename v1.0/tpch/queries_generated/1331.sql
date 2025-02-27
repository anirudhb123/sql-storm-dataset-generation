WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ss.s_name AS supplier_name,
    ss.total_available,
    ss.avg_supply_cost,
    c.c_name AS customer_name,
    coc.order_count,
    od.total_price AS order_total
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    CustomerOrderCount coc ON ss.s_suppkey = coc.c_custkey
LEFT JOIN 
    OrderDetails od ON coc.order_count = 1
WHERE 
    (ss.total_available IS NOT NULL OR coc.order_count IS NULL)
ORDER BY 
    r.r_name, n.n_name, ss.s_name;
