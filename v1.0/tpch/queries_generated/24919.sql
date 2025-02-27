WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.s_suppkey,
    r.s_name,
    c.c_name,
    pd.p_name,
    pd.total_quantity,
    pd.avg_price,
    CASE 
        WHEN r.rank <= 3 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_tier
FROM 
    RankedSuppliers r
JOIN 
    FilteredCustomers c ON r.s_suppkey = c.c_custkey
JOIN 
    ProductDetails pd ON r.s_suppkey = pd.p_partkey 
WHERE 
    (c.total_orders < 15 OR pd.avg_price IS NULL)
    AND (pd.total_quantity > 100 OR r.s_acctbal <= ALL (SELECT s.s_acctbal FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')))
ORDER BY 
    c.c_name, pd.avg_price DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
