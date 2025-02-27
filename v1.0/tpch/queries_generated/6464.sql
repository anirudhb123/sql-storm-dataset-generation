WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rs.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(os.total_revenue) AS total_revenue,
    AVG(ss.avg_supply_cost) AS avg_supply_cost,
    SUM(ss.total_available_quantity) AS total_available_quantity
FROM 
    region rs
JOIN 
    nation n ON rs.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    OrderStats os ON os.o_orderkey IN (
        SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey
    )
JOIN 
    SupplierStats ss ON ss.s_suppkey = s.s_suppkey
GROUP BY 
    rs.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
