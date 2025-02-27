WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
BestSuppliers AS (
    SELECT 
        r.p_partkey,
        r.s_suppkey,
        r.s_name,
        r.s_acctbal
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank = 1
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey
),
CustomerMetrics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    bs.s_name AS best_supplier,
    cm.c_name AS top_customer,
    cm.total_spent,
    COALESCE(os.total_sales, 0) AS order_sales
FROM 
    part p
LEFT JOIN 
    BestSuppliers bs ON bs.p_partkey = p.p_partkey
LEFT JOIN 
    CustomerMetrics cm ON cm.order_count = (
        SELECT MAX(order_count)
        FROM CustomerMetrics c2
        WHERE c2.c_custkey = cm.c_custkey
    )
LEFT JOIN 
    OrderStats os ON os.o_orderkey = (
        SELECT o_orderkey
        FROM OrderStats
        ORDER BY total_sales DESC
        LIMIT 1
    )
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
    ) OR p.p_mfgr IS NULL
ORDER BY 
    p.p_partkey DESC, cm.total_spent DESC;
