WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) as total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT AVG(ps_supplycost * ps_availqty) 
            FROM partsupp ps
        )
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        l.l_partkey
),
FilteredSales AS (
    SELECT 
        ts.l_partkey,
        ts.total_sales,
        ts.order_count,
        CASE
            WHEN ts.order_count > 10 THEN 'High Volume'
            WHEN ts.order_count BETWEEN 5 AND 10 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS sales_category
    FROM 
        TotalSales ts
    WHERE 
        ts.total_sales > 10000
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
)
SELECT 
    co.c_name,
    co.o_orderdate,
    co.o_totalprice,
    hs.s_name AS supplier_name,
    fs.sales_category,
    rp.p_name,
    rp.p_retailprice
FROM 
    CustomerOrders co
LEFT JOIN 
    HighValueSuppliers hs ON co.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey IN (
            SELECT p.p_partkey 
            FROM RankedParts rp 
            WHERE rp.price_rank <= 10
        )
    )
JOIN 
    FilteredSales fs ON fs.l_partkey = (
        SELECT l.l_partkey 
        FROM lineitem l 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_custkey = co.c_custkey 
        ORDER BY l.l_extendedprice DESC 
        LIMIT 1
    )
JOIN 
    RankedParts rp ON rp.p_partkey = fs.l_partkey
WHERE 
    co.rn = 1
ORDER BY 
    co.o_totalprice DESC, 
    hs.total_supply_value ASC
LIMIT 50;
