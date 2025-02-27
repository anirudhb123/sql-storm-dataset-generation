WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
AggregatedParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost IS NOT NULL
    GROUP BY 
        ps.ps_partkey
),
CriticalOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
),
EnhancedStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        np.n_name AS nation_name,
        ap.total_availqty,
        ap.avg_supplycost,
        COALESCE(MAX(co.total_value), 0) AS max_order_value,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM 
        part p
    LEFT JOIN 
        AggregatedParts ap ON p.p_partkey = ap.ps_partkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.s_nationkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.s_nationkey)
    LEFT JOIN 
        CriticalOrders co ON co.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = 
            (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = rs.s_nationkey AND c.c_acctbal >= 500))
    LEFT JOIN 
        nation np ON rs.s_nationkey = np.n_nationkey
    LEFT JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name, np.n_name, ap.total_availqty, ap.avg_supplycost
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.nation_name,
    p.total_availqty,
    p.avg_supplycost,
    p.max_order_value,
    p.return_count
FROM 
    EnhancedStatistics p
WHERE 
    p.total_availqty > (SELECT AVG(total_availqty) FROM EnhancedStatistics) 
    AND p.avg_supplycost < (SELECT MIN(avg_supplycost) FROM EnhancedStatistics)
ORDER BY 
    p.max_order_value DESC, p.return_count ASC
FETCH FIRST 10 ROWS ONLY;
