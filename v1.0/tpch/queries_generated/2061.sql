WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
), 
RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
)
SELECT 
    r.r_name,
    SUM(COALESCE(ss.total_supplycost, 0)) AS supply_cost_sum,
    AVG(os.total_orders) AS avg_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderSummary os ON s.s_nationkey = os.c_custkey
LEFT JOIN 
    RankedLineItems rli ON rli.l_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = s.s_suppkey AND ps.ps_availqty > 0
    )
JOIN 
    part p ON p.p_partkey = rli.l_partkey
GROUP BY 
    r.r_name
HAVING 
    SUM(ss.total_supplycost) > 0 AND AVG(os.total_orders) IS NOT NULL
ORDER BY 
    supply_cost_sum DESC, avg_order_value DESC;
