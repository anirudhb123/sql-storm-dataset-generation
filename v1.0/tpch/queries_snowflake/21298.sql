
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F' AND 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        sd.*,
        RANK() OVER (ORDER BY sd.total_supplycost DESC) AS supplier_rank
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supplycost IS NOT NULL AND 
        sd.nation_name IN (SELECT r.r_name FROM region r WHERE r.r_regionkey < 3)
    HAVING 
        COUNT(sd.s_suppkey) > 1
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    t.s_name AS supplier_name,
    t.nation_name,
    t.total_supplycost,
    CASE 
        WHEN o.o_totalprice > 50000 THEN 'High Value'
        WHEN o.o_totalprice BETWEEN 20000 AND 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    RankedOrders o
LEFT JOIN 
    TopSuppliers t ON o.o_orderkey = (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey 
        LIMIT 1)
WHERE 
    t.supplier_rank <= 5 OR t.supplier_rank IS NULL
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice ASC;
