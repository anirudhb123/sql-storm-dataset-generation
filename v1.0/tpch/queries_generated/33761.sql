WITH RECURSIVE supply_chain AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name,
        1 AS level
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0

    UNION ALL

    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name,
        level + 1
    FROM 
        partsupp ps
    JOIN 
        supply_chain sc ON ps.ps_partkey = sc.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        level < 3
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
part_expenditure AS (
    SELECT 
        li.l_partkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY li.l_partkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem li
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    GROUP BY 
        li.l_partkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(e.total_revenue, 0) AS total_revenue,
    COALESCE(e.order_count, 0) AS order_count,
    MAX(sc.s_name) AS supplier_name,
    MAX(sc.level) AS supply_chain_level,
    cs.total_spent,
    cs.order_count AS total_orders
FROM 
    part p
LEFT JOIN 
    part_expenditure e ON p.p_partkey = e.l_partkey
LEFT JOIN 
    supply_chain sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN 
    customer_order_summary cs ON cs.c_custkey = (
        SELECT 
            c.c_custkey
        FROM 
            customer c
        WHERE 
            c.c_acctbal = (
                SELECT 
                    MAX(c2.c_acctbal)
                FROM 
                    customer c2
                WHERE 
                    c2.c_nationkey = (
                        SELECT 
                            n.n_nationkey
                        FROM 
                            nation n
                        WHERE 
                            n.n_name = 'USA'
                    )
            )
    )
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, cs.total_spent, cs.order_count
ORDER BY 
    total_revenue DESC, cs.total_spent DESC
LIMIT 10;
