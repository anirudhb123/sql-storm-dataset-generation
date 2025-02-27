WITH SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationVolume AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(l.l_quantity) IS NOT NULL
)

SELECT 
    p.p_partkey,
    p.p_name,
    ss.total_available_qty,
    ss.supplier_count,
    ss.avg_supply_cost,
    od.total_revenue,
    nv.n_name,
    nv.total_quantity
FROM 
    part p
LEFT JOIN 
    SupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE 
            l.l_returnflag = 'N' 
            AND o.o_orderdate >= '1997-01-01'
    )
LEFT JOIN 
    NationVolume nv ON nv.n_nationkey = (
        SELECT 
            s.s_nationkey 
        FROM 
            supplier s 
        JOIN 
            partsupp ps ON s.s_suppkey = ps.ps_suppkey 
        WHERE 
            ps.ps_partkey = p.p_partkey 
        LIMIT 1
    )
WHERE 
    p.p_retailprice IS NOT NULL 
ORDER BY 
    total_revenue DESC, 
    p.p_partkey
LIMIT 100;