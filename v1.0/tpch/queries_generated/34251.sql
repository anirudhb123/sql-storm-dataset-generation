WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS hierarchy_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'

    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.hierarchy_level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierPartCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_comment LIKE '%some condition%'
),
AggregatedLineItems AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_discount) AS avg_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(sp.supplier_count, 0) AS supplier_count,
    COALESCE(cs.total_spent, 0) AS total_spent,
    al.total_revenue,
    al.avg_discount
FROM 
    part p
LEFT JOIN 
    SupplierPartCount sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    CustomerSpend cs ON p.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        JOIN orders o ON ps.ps_suppkey = o.o_custkey
        WHERE o.o_orderstatus = 'O'
    )
LEFT JOIN 
    AggregatedLineItems al ON p.p_partkey = al.l_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    total_revenue DESC, 
    p.p_name ASC;
