WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
supplier_part_info AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
customer_performance AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    np.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(cp.total_spent) AS average_spent,
    SUM(spi.profit_margin) AS total_profit_margin,
    ROW_NUMBER() OVER (ORDER BY AVG(cp.total_spent) DESC) AS rank_by_spent
FROM 
    nation np
LEFT JOIN 
    customer c ON np.n_nationkey = c.c_nationkey
LEFT JOIN 
    customer_performance cp ON c.c_custkey = cp.c_custkey
LEFT JOIN 
    supplier_part_info spi ON spi.ps_partkey IN (
        SELECT ps_partkey
        FROM partsupp
        WHERE ps_availqty > 0
    )
WHERE 
    c.c_acctbal IS NOT NULL
GROUP BY 
    np.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_profit_margin DESC;
