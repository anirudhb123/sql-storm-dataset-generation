WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        STRING_AGG(DISTINCT l.l_shipmode, ', ') AS ship_modes
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    sd.nation_name,
    sd.part_count,
    sd.total_supplycost,
    sd.part_names,
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.lineitem_count,
    co.order_total,
    co.ship_modes
FROM 
    SupplierDetails sd
JOIN 
    CustomerOrders co ON sd.part_count > 5 AND co.lineitem_count > 5
ORDER BY 
    sd.total_supplycost DESC, co.order_total DESC;
