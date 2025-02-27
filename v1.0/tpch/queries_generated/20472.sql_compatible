
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name,
        rs.part_count
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
ProductDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        COALESCE(p.p_size, 0) AS size
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
LineItemCalculations AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_custkey, 
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    pd.p_name AS product_name,
    lc.net_sales,
    lc.total_quantity,
    CASE 
        WHEN ts.part_count IS NULL THEN 'Supplier not in top 3'
        ELSE 'Supplier in top 3'
    END AS supplier_status
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON co.c_custkey = ts.s_suppkey
JOIN 
    ProductDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN 
    LineItemCalculations lc ON lc.l_orderkey = co.c_custkey
WHERE 
    (lc.net_sales > 1000 AND lc.total_quantity BETWEEN 1 AND 10)
    OR (lc.total_quantity > 10 AND lc.total_quantity < 20)
    OR (lc.net_sales IS NULL)
ORDER BY 
    co.total_spent DESC,
    supplier_name
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
