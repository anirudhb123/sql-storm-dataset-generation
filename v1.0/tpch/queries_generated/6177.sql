WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    ss.s_name,
    ss.nation,
    ss.total_supply_cost,
    ss.num_parts,
    os.o_orderkey,
    os.o_orderstatus,
    os.revenue,
    os.avg_quantity
FROM 
    SupplierStats ss
LEFT JOIN 
    OrderStats os ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')))
ORDER BY 
    ss.total_supply_cost DESC, os.revenue DESC
LIMIT 100;
