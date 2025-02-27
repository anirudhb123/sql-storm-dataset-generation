WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), AggregateLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), SupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        ps.ps_availqty, 
        CASE 
            WHEN ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp) THEN 'above_average'
            ELSE 'below_average'
        END AS availability_status
    FROM 
        partsupp ps
)
SELECT 
    n.n_name,
    COALESCE(SUM(a.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names,
    AVG(RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal)) AS avg_rank,
    MAX(CASE WHEN sa.availability_status = 'above_average' THEN sa.ps_partkey END) AS max_above_avg_partkey
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    AggregateLineItems a ON a.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM SupplierAvailability sa WHERE sa.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey))
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
