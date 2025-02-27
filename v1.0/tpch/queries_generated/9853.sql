WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
best_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        DATEDIFF(CURRENT_DATE, o.o_orderdate) AS order_age
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
)
SELECT 
    rp.p_name,
    rp.p_brand,
    bs.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.o_orderkey,
    co.o_totalprice,
    co.order_age
FROM 
    ranked_parts rp
JOIN 
    best_suppliers bs ON rp.rank = 1
JOIN 
    lineitem li ON rp.p_partkey = li.l_partkey
JOIN 
    customer_orders co ON co.o_orderkey = li.l_orderkey
WHERE 
    EXISTS (
        SELECT 1
        FROM nation n
        WHERE n.n_nationkey = bs.s_nationkey
        AND n.n_name IN ('FRANCE', 'GERMANY')
    )
ORDER BY 
    co.o_totalprice DESC, rp.total_cost DESC;
