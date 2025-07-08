WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
), OrderSummaries AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        COUNT(l.l_orderkey) AS lineitem_count, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    rs.nation_name,
    rs.s_name, 
    rs.total_available_qty, 
    os.lineitem_count, 
    os.total_revenue
FROM 
    RankedSuppliers rs
JOIN 
    OrderSummaries os ON os.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_address LIKE '%' || rs.nation_name || '%')
WHERE 
    rs.rank <= 5 
ORDER BY 
    rs.total_supply_cost DESC, 
    os.total_revenue DESC;
