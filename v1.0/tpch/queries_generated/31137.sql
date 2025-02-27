WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    
    UNION ALL

    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        co.level + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
        AND co.level < 5
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sp.s_supname,
        ROW_NUMBER() OVER (ORDER BY SUM(sp.total_supplycost) DESC) AS rank
    FROM 
        SupplierParts sp
    GROUP BY 
        sp.s_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    co.o_orderstatus,
    COALESCE(ts.s_suppname, 'No Supplier') AS supplier_name,
    COUNT(DISTINCT l.l_lineitemkey) AS line_items_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(l.l_discount) > 0.10 THEN 'High Discount'
        WHEN SUM(l.l_discount) BETWEEN 0.05 AND 0.10 THEN 'Medium Discount'
        ELSE 'Low Discount'
    END AS discount_category
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_partkey = ts.s_supname
WHERE 
    co.o_orderstatus = 'F'
GROUP BY 
    co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, co.o_orderstatus, ts.s_suppname
HAVING 
    COUNT(DISTINCT l.l_lineitemkey) > 0
ORDER BY 
    co.o_orderdate DESC, total_revenue DESC;
