WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_partkey,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_extendedprice DESC) AS line_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
CustomerInsights AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ci.c_name,
    ci.total_spent,
    ci.order_count,
    COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
    SUM(h.total_line_value) AS total_high_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    CustomerInsights ci ON ci.c_custkey IN (
        SELECT DISTINCT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey
    )
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = ci.c_custkey AND o.o_orderstatus = 'O'
    )
LEFT JOIN 
    SupplyChain sc ON sc.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            WHERE o.o_custkey = ci.c_custkey
        )
    )
WHERE 
    ci.total_spent > 1000
GROUP BY 
    r.r_name, n.n_name, ci.c_name, ci.total_spent, ci.order_count
ORDER BY 
    region_name, nation_name, total_spent DESC;
