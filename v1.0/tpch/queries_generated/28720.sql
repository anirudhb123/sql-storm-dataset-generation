WITH RecursivePartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE LENGTH(p.p_comment) > 0

    UNION ALL

    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_container,
        rp.p_retailprice,
        rp.p_comment,
        SUBSTRING(rp.p_comment, 1, 10),
        LENGTH(rp.p_comment)
    FROM RecursivePartDetails rpd
    JOIN part rp ON rpd.p_partkey = rp.p_partkey
    WHERE LENGTH(rp.p_comment) > LENGTH(rpd.p_comment)
),
CountByNation AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS average_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
TopCustomers AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
    ORDER BY total_spent DESC
    LIMIT 5
)
SELECT 
    r.n_name,
    r.supplier_count,
    r.average_balance,
    t.c_name,
    t.total_spent
FROM CountByNation r
JOIN TopCustomers t ON r.n_name LIKE '%' || SUBSTRING(t.c_name FROM 1 FOR 3) || '%'
ORDER BY r.n_name, t.total_spent DESC;
