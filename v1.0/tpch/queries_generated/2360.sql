WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    COALESCE(r.total_avail_qty, 0) AS available_quantity,
    cn.total_spent,
    p.p_retailprice * (1 - AVG(l.l_discount) OVER (PARTITION BY l.l_partkey)) AS avg_price_after_discount
FROM 
    part p
LEFT JOIN 
    SupplierParts r ON p.p_partkey = r.ps_partkey AND r.rn = 1
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerNation cn ON cn.c_custkey = (SELECT TOP 1 o.o_custkey FROM RankedOrders o WHERE o.o_orderkey = l.l_orderkey)
WHERE 
    (p.p_size BETWEEN 10 AND 20 AND p.p_type LIKE '%plastic%') OR
    (p.p_comment IS NOT NULL AND p.p_comment LIKE '%top%')
ORDER BY 
    avg_price_after_discount DESC,
    available_quantity DESC;
