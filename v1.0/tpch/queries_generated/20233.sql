WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(DISTINCT l.l_partkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    p.p_name,
    p.p_retailprice,
    s.s_name,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'VIP Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY p.p_retailprice DESC) AS row_num
FROM 
    region r
LEFT JOIN 
    RankedParts p ON CHARINDEX('A', p.p_name) > 0
JOIN 
    TopSuppliers s ON s.total_supply_cost > 1000
LEFT JOIN 
    RecentOrders o ON o.o_orderdate IS NOT NULL
JOIN 
    SupplierDetails sd ON s.s_nationkey = sd.supplier_count
WHERE 
    p.price_rank <= 3 AND 
    (s.s_name LIKE '%Inc.' OR s.s_name IS NULL)
GROUP BY 
    r.r_name, p.p_name, p.p_retailprice, s.s_name
HAVING 
    SUM(CASE WHEN o.lineitem_count IS NULL THEN 0 ELSE o.lineitem_count END) > 10 
ORDER BY 
    r.r_name, p.p_retailprice DESC, row_num;
