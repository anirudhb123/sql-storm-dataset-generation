
WITH OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    os.o_orderkey,
    os.total_revenue,
    os.supplier_count,
    ss.total_supplycost,
    ss.avg_supplycost,
    ROW_NUMBER() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
FROM 
    OrderStats os
JOIN 
    SupplierStats ss ON os.supplier_count = (SELECT COUNT(DISTINCT l.l_suppkey) FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
WHERE 
    ss.total_supplycost > 50000
ORDER BY 
    os.total_revenue DESC, ss.total_supplycost ASC
LIMIT 100;
