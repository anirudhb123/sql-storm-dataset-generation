WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey
), 
PartStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
), 
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)

SELECT 
    rs.region_name,
    ps.p_name,
    ps.total_available_quantity,
    ps.average_supply_cost,
    os.o_orderstatus,
    os.total_revenue
FROM 
    RegionStats rs
JOIN 
    PartStats ps ON ps.total_available_quantity > 500
JOIN 
    OrderStats os ON os.total_revenue > 100000
ORDER BY 
    rs.region_name, ps.average_supply_cost DESC;
