WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IS NOT NULL
),
PartSupply AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 100
),
QualifiedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS order_status,
        o.o_orderdate
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_avail_qty, 0) AS available_quantity,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(qo.o_totalprice, 0) AS order_total,
    CASE 
        WHEN qo.order_status = 'Finalized' AND rs.rnk = 1 THEN 'Top Supplier for Finalized Orders'
        ELSE 'Other'
    END AS supplier_category
FROM 
    part p
LEFT JOIN 
    PartSupply ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1 OR rs.s_suppkey IS NULL
LEFT JOIN 
    QualifiedOrders qo ON qo.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
WHERE 
    p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty IS NOT NULL)
ORDER BY 
    p.p_partkey, available_quantity DESC
FETCH FIRST 100 ROWS ONLY;
