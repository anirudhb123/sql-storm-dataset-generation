WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON s.s_suppkey = rs.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
FinalResult AS (
    SELECT 
        sd.region,
        sd.nation,
        sd.s_name,
        hvo.total_value,
        hvo.part_count,
        ROW_NUMBER() OVER (PARTITION BY sd.region ORDER BY hvo.total_value DESC) AS order_rank
    FROM 
        SupplierDetails sd
    JOIN 
        HighValueOrders hvo ON sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
)
SELECT 
    region,
    nation,
    s_name,
    total_value,
    part_count
FROM 
    FinalResult
WHERE 
    order_rank <= 10
ORDER BY 
    region, total_value DESC;
