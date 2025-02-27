WITH SupplierTotals AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' -- Filtering orders this year
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)

SELECT 
    od.o_orderkey,
    od.total_price,
    od.line_item_count,
    st.total_supply_cost,
    rs.nation_count
FROM 
    OrderDetails od
LEFT JOIN 
    SupplierTotals st ON od.o_custkey = st.s_suppkey -- Assuming there's logic to relate customers and suppliers
JOIN 
    RegionStats rs ON od.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rs.r_regionkey) LIMIT 1) -- Alert: correlated subquery
WHERE 
    (st.total_supply_cost > 1000 OR od.total_price > 5000) -- Complex predicates
    AND rs.nation_count > 1 -- Ensuring at least two nations in the region
ORDER BY 
    od.total_price DESC, st.total_supply_cost ASC; -- Multi-level ordering
