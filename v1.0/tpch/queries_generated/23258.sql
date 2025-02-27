WITH RankedNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_regionkey,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, n.n_regionkey
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N' 
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
CumulativeValues AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice) OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS cumulated_value 
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
), 
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        CASE 
            WHEN p.p_size IS NULL THEN 0 
            ELSE p.p_size
        END AS adjusted_size 
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
    AND 
        EXISTS (
            SELECT 1 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty > 0
        )
)
SELECT 
    n.n_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(c.cumulated_value) AS total_cumulative_value, 
    COUNT(DISTINCT p.p_partkey) AS distinct_part_count,
    AVG(DISTINCT p.adjusted_size) AS avg_adjusted_size
FROM 
    RankedNation n
LEFT JOIN 
    HighValueOrders o ON n.n_nationkey = (SELECT c.cust_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN 
    CumulativeValues c ON o.o_orderkey = c.o_orderkey 
LEFT JOIN 
    FilteredParts p ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey) LIMIT 1) 
WHERE 
    n.nation_rank = 1
GROUP BY 
    n.n_name
HAVING 
    SUM(c.cumulated_value) > 5000
ORDER BY 
    order_count DESC, 
    total_cumulative_value ASC;
