WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F' 
),
TopOrders AS (
    SELECT
        oh.o_orderkey,
        oh.o_orderdate,
        oh.o_totalprice,
        oh.c_name,
        n.n_name AS nation_name
    FROM 
        OrderHierarchy oh
    JOIN 
        nation n ON oh.c_nationkey = n.n_nationkey
    WHERE 
        oh.rank <= 5
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_name,
        p.p_retailprice,
        COALESCE(sc.supplier_count, 0) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        SupplierCount sc ON p.p_partkey = sc.ps_partkey
)
SELECT 
    TOP 10 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    p.p_name,
    p.p_retailprice,
    p.supplier_count,
    CASE 
        WHEN o.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS order_type,
    COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS lineitem_count
FROM 
    TopOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    PartDetails p ON l.l_partkey = p.p_partkey
WHERE 
    p.supplier_count > 5
ORDER BY 
    o.o_totalprice DESC, o.o_orderdate ASC;
