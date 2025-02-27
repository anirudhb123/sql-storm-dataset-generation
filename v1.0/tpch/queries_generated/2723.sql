WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_container
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
        AND p.p_size IN (SELECT DISTINCT ps.ps_supplycost FROM partsupp ps)
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(LENGTH(l.l_comment)) AS total_comment_length
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_name,
    co.total_orders,
    co.total_spent,
    sp.s_name,
    pd.p_name,
    pd.p_brand,
    pd.p_retailprice,
    ali.total_revenue,
    ali.total_comment_length
FROM 
    CustomerOrders co
LEFT JOIN 
    AggregatedLineItems ali ON ali.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
LEFT JOIN 
    SupplierParts sp ON sp.total_avail_qty > 100
JOIN 
    PartDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey)
WHERE 
    co.total_spent > 500
ORDER BY 
    co.total_spent DESC, ali.total_revenue DESC
LIMIT 100;

