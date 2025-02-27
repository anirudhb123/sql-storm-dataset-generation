WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 1
            ELSE 0
        END AS is_finalized
    FROM 
        orders o
    WHERE 
        o.o_totalprice BETWEEN 100.00 AND 10000.00 
        AND o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
NationalSupplierStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(ps.ps_availqty, 0) AS availability,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    ns.unique_suppliers,
    ns.total_supplycost,
    fs.o_totalprice,
    fs.o_orderdate,
    CASE 
        WHEN fs.is_finalized = 1 THEN 'Completed'
        ELSE 'Pending'
    END AS order_status,
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rnk = 1
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    FilteredOrders fs ON li.l_orderkey = fs.o_orderkey
JOIN 
    NationalSupplierStats ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 50.00)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, ps.ps_availqty, fs.o_totalprice, fs.o_orderdate, 
    s.s_name, n.n_name, fs.is_finalized
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000.00
ORDER BY 
    total_revenue DESC NULLS LAST;
