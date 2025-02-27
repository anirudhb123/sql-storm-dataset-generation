WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > '1995-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
),
supplier_parts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
low_avail_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        sp.ps_availqty
    FROM 
        part p
    LEFT JOIN 
        supplier_parts sp ON p.p_partkey = sp.ps_partkey
    WHERE 
        sp.ps_availqty < 100
),
nations_with_comments AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_comment,
        CASE 
            WHEN n.n_comment IS NOT NULL AND LENGTH(n.n_comment) > 50 THEN 'Long Comment'
            ELSE 'Short Comment'
        END AS comment_type
    FROM 
        nation n
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    n.n_name AS nation_name,
    lp.p_name AS low_avail_part,
    COUNT(lp.p_partkey) AS part_count,
    DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY ro.o_totalprice DESC) AS nation_rank
FROM 
    ranked_orders ro
JOIN 
    customer c ON ro.o_orderkey = c.c_custkey
LEFT JOIN 
    nations_with_comments n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    low_avail_parts lp ON lp.p_partkey = ANY (
        SELECT DISTINCT ps.ps_partkey
        FROM partsupp ps
        WHERE ps.ps_availqty IS NOT NULL AND ps.ps_availqty <= 100
    )
WHERE 
    ro.order_rank <= 10
GROUP BY 
    ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, n.n_name, lp.p_name
HAVING 
    SUM(ro.o_totalprice) > 1000.00
ORDER BY 
    ro.o_orderdate DESC, nation_rank ASC;
