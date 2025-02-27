WITH RECURSIVE price_agg AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    UNION ALL
    SELECT 
        p.p_partkey,
        p.p_name,
        pa.total_cost + (SELECT SUM(l.l_extendedprice * (1 - l.l_discount))
                          FROM lineitem l
                          JOIN orders o ON l.l_orderkey = o.o_orderkey
                          WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '30' DAY 
                          AND o.o_orderstatus = 'F')
    FROM 
        price_agg pa
    JOIN 
        part p ON pa.p_partkey = p.p_partkey
),
nation_totals AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS suppliers_count,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    nt.suppliers_count,
    nt.total_balance,
    p.p_name,
    COALESCE(pa.total_cost, 0) AS collective_price,
    os.order_total,
    os.order_rank
FROM 
    nation_totals nt
LEFT JOIN 
    nation n ON nt.n_nationkey = n.n_nationkey
LEFT JOIN 
    price_agg pa ON pa.p_partkey = (
        SELECT p.p_partkey
        FROM part p
        ORDER BY p.p_retailprice DESC
        LIMIT 1
    )
LEFT JOIN 
    order_summary os ON os.o_orderkey = (
        SELECT o.o_orderkey
        FROM orders o
        ORDER BY o.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    n.n_regionkey IS NOT NULL
ORDER BY 
    total_balance DESC, 
    suppliers_count DESC;
