WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        NTILE(4) OVER (ORDER BY p.p_retailprice) AS price quartile,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_size DESC) AS brand_rank
    FROM 
        part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
),
PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty IS NOT NULL
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    COALESCE(rp.p_retailprice, 0) AS retail_price,
    fs.total_supply_cost,
    ro.o_orderkey,
    ro.o_totalprice,
    psc.supplier_count
FROM 
    RankedParts rp
LEFT JOIN 
    FilteredSuppliers fs ON rp.p_partkey = fs.s_suppkey
FULL OUTER JOIN 
    RecentOrders ro ON ro.o_orderkey = fs.total_supply_cost
JOIN 
    PartSupplierCount psc ON psc.ps_partkey = rp.p_partkey
WHERE 
    (rp.p_retailprice IS NOT NULL AND rp.price quartile = 1) 
    OR 
    (rp.brand_rank <= 5 AND fs.total_supply_cost IS NOT NULL)
ORDER BY 
    retail_price DESC, supplier_count ASC
LIMIT 100;
