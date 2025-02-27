WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_name LIKE 'Supplier%'
        )
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    ns.n_name AS supplier_nation,
    COALESCE(rs.s_acctbal, 0) AS highest_supplier_acctbal,
    od.total_revenue,
    CASE 
        WHEN od.total_revenue IS NULL THEN 'No Revenue'
        WHEN od.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category,
    ROW_NUMBER() OVER (ORDER BY p.p_partkey) AS part_row_num
FROM 
    part p
LEFT JOIN 
    RankedSupplier rs ON p.p_partkey = rs.s_suppkey
JOIN 
    nation ns ON ns.n_nationkey = rs.s_suppkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O' 
        FETCH FIRST 1 ROW ONLY
    )
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
    )
ORDER BY 
    p.p_partkey, revenue_category
LIMIT 100
UNION ALL
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    ns.n_name AS supplier_nation,
    COALESCE(rs.s_acctbal, 0) AS highest_supplier_acctbal,
    NULL AS total_revenue,
    'No Revenue' AS revenue_category,
    ROW_NUMBER() OVER (ORDER BY p.p_partkey) AS part_row_num
FROM 
    part p
LEFT JOIN 
    RankedSupplier rs ON p.p_partkey = rs.s_suppkey
JOIN 
    nation ns ON ns.n_nationkey = rs.s_nationkey
WHERE 
    p.p_retailprice <= (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
    )
ORDER BY 
    p.p_partkey;
