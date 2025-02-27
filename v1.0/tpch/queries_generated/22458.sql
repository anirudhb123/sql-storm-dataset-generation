WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AverageLineItemValue AS (
    SELECT 
        o.o_orderkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2022-01-01'
    GROUP BY 
        o.o_orderkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        a.avg_value,
        ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    LEFT JOIN 
        AverageLineItemValue a ON o.o_orderkey = a.o_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F', 'P')
)
SELECT 
    r.r_regionkey,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(CASE WHEN fo.order_rank <= 10 THEN fo.o_totalprice END), 0) AS top_order_total,
    STRING_AGG(DISTINCT p.p_name, ', ') AS parts_summary
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    FilteredOrders fo ON fo.o_orderkey IN (
        SELECT 
            l.l_orderkey
        FROM 
            lineitem l
        WHERE 
            l.l_returnflag = 'R'
    )
LEFT JOIN 
    partsupp ps ON ps.ps_partkey IN (
        SELECT 
            p.p_partkey
        FROM 
            part p
        WHERE 
            p.p_size < 20 AND p.p_retailprice < (SELECT AVG(p_retailprice) FROM part)
    )
WHERE 
    c.c_acctbal IS NOT NULL
GROUP BY 
    r.r_regionkey, r.r_name
HAVING 
    SUM(COALESCE(fo.o_totalprice, 0)) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate >= '2022-01-01')
ORDER BY 
    r.r_name;
