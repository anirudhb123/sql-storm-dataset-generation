WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CombinedStats AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.nation_name,
        ss.part_count,
        ss.total_supply_cost,
        os.o_orderkey,
        os.total_revenue
    FROM 
        SupplierStats ss
    LEFT JOIN 
        OrderStats os ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01')))
)
SELECT 
    cs.nation_name,
    COUNT(cs.s_suppkey) AS supplier_count,
    SUM(cs.total_supply_cost) AS total_supply_cost,
    SUM(cs.total_revenue) AS total_revenue
FROM 
    CombinedStats cs
GROUP BY 
    cs.nation_name
ORDER BY 
    supplier_count DESC, total_revenue DESC
LIMIT 10;
