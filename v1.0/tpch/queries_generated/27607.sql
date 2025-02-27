WITH PartStatistics AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        SUBSTR(p.p_comment, 1, 20) AS short_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
NationStatistics AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        UPPER(n.n_comment) AS upper_comment
    FROM 
        nation n
),
CustomerStatistics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CONVERT(c.c_address USING utf8) AS utf8_address,
        c.c_mktsegment,
        CONCAT('Segment: ', c.c_mktsegment, ', Balance: ', CAST(c.c_acctbal AS CHAR)) AS formatted_balance
    FROM 
        customer c
)
SELECT 
    ps.p_partkey,
    ps.name_length,
    ps.short_comment,
    ps.supplier_count,
    ns.n_name AS nation_name,
    cs.utf8_address,
    cs.formatted_balance
FROM 
    PartStatistics ps
JOIN 
    NationStatistics ns ON ns.n_nationkey = (
        SELECT s.s_nationkey
        FROM supplier s
        JOIN partsupp p ON p.ps_suppkey = s.s_suppkey
        WHERE p.ps_partkey = ps.p_partkey
        LIMIT 1
    )
JOIN 
    CustomerStatistics cs ON cs.c_custkey = (
        SELECT o.o_custkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = ps.p_partkey
        LIMIT 1
    )
ORDER BY 
    ps.name_length DESC, 
    ps.supplier_count ASC;
