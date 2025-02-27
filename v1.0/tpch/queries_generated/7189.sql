WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PopularParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availability,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ps.ps_supplycost) AS high_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    os.total_orders,
    os.total_revenue,
    rs.nation AS supplier_nation,
    rp.total_availability,
    rp.high_supply_cost
FROM 
    customer c
LEFT JOIN 
    OrderSummary os ON c.c_custkey = os.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = rs.nation
LEFT JOIN 
    PopularParts rp ON rp.ps_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_orderstatus = 'O'
    )
WHERE 
    os.total_revenue > 10000
ORDER BY 
    os.total_revenue DESC, c.c_acctbal;
