WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > (
            SELECT AVG(ps2.ps_availqty)
            FROM partsupp ps2
            WHERE ps2.ps_partkey = ps.ps_partkey
        )
), 
Stats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
OrdersStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    s.s_name,
    ss.total_available,
    ss.supplier_count,
    os.total_revenue,
    os.line_item_count
FROM 
    RankedSuppliers s
JOIN 
    Stats ss ON s.s_suppkey = ss.p_partkey
FULL OUTER JOIN 
    OrdersStats os ON ss.p_partkey = os.o_orderkey
WHERE 
    (ss.total_available IS NOT NULL OR os.total_revenue IS NOT NULL)
    AND (s.rank = 1 OR os.line_item_count > 10)
ORDER BY 
    ss.total_available DESC, 
    os.total_revenue DESC;
