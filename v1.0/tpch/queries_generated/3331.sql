WITH SupplierTotals AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        st.total_supply_cost,
        RANK() OVER (ORDER BY st.total_supply_cost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        SupplierTotals st ON s.s_suppkey = st.s_suppkey
), CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), TotalOrderValue AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
)

SELECT 
    r.r_name, 
    COUNT(DISTINCT ns.n_nationkey) AS nation_count, 
    SUM(COALESCE(ct.total_order_value, 0)) AS total_value,
    AVG(ct.avg_order_value) AS average_order_value,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count 
FROM 
    nation ns
LEFT JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrderStats ct ON ns.n_nationkey = ct.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rank <= 5
WHERE 
    r.r_name LIKE 'N%' OR rs.total_supply_cost > 10000
GROUP BY 
    r.r_name
HAVING 
    AVG(ct.order_count) > 1
ORDER BY 
    total_value DESC, 
    nation_count ASC;
