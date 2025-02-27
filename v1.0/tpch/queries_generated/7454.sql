WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
), RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(s.total_supply_cost) AS total_suppliers_cost,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    rs.r_name AS Region,
    ss.s_name AS Supplier,
    os.o_orderstatus AS Order_Status,
    SUM(os.total_revenue) AS Total_Revenue,
    rs.total_suppliers_cost AS Total_Suppliers_Cost,
    rs.nation_count AS Nation_Count,
    COUNT(DISTINCT ss.s_suppkey) AS Unique_Suppliers
FROM RegionStats rs
JOIN SupplierStats ss ON rs.total_suppliers_cost > 100000
JOIN OrderStats os ON os.total_revenue > 50000
GROUP BY rs.r_name, ss.s_name, os.o_orderstatus
ORDER BY Total_Revenue DESC, Region ASC;
