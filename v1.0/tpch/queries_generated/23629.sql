WITH RegionSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(*) AS number_of_suppliers
    FROM 
        RegionSuppliers r
    WHERE 
        rank <= 5
    GROUP BY 
        r.r_regionkey, r.r_name
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
    WHERE 
        o.o_totalprice > 100 AND 
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        c.c_custkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    p.p_retailprice,
    SUM(ps.ps_availqty) AS total_availqty,
    COALESCE(AVG(co.total_spent), 0) AS avg_customer_spending,
    CASE 
        WHEN COUNT(DISTINCT rs.s_suppkey) > 0 THEN 'Available'
        ELSE 'Not Available'
    END AS supplier_status
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RegionSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
LEFT JOIN 
    CustomerOrders co ON rs.s_suppkey = co.c_custkey
GROUP BY 
    ps.ps_partkey, p.p_name, p.p_retailprice
HAVING 
    SUM(ps.ps_availqty) > 0 AND 
    p.p_size BETWEEN 10 AND 50 AND 
    STRING_AGG(DISTINCT p.p_comment, ', ') WITHIN GROUP (ORDER BY p.p_comment) IS NOT NULL
ORDER BY 
    total_availqty DESC
OFFSET 10 ROWS 
FETCH NEXT 20 ROWS ONLY;
