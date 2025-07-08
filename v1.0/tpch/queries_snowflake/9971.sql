WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(li.l_orderkey) AS total_line_items,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.total_avail_qty,
    r.total_cost,
    h.s_name AS high_value_supplier,
    os.total_line_items,
    os.total_revenue
FROM 
    RankedParts r
JOIN 
    HighValueSuppliers h ON h.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = r.p_partkey
    )
JOIN 
    OrderSummary os ON os.total_line_items > 10
ORDER BY 
    r.total_cost DESC, 
    os.total_revenue DESC;