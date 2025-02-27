WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
),
EligibleOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate >= DATEADD(month, -3, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
SupplierNation AS (
    SELECT 
        n.n_name,
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
    COALESCE(SN.supplier_count, 0) AS total_suppliers,
    EO.o_orderkey,
    EO.total_revenue,
    EO.item_count,
    RANK() OVER (PARTITION BY r.r_name ORDER BY EO.total_revenue DESC) AS revenue_rank
FROM 
    region r
LEFT JOIN 
    SupplierNation SN ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        WHERE n.n_name = r.r_name
    )
JOIN 
    EligibleOrders EO ON EO.o_totalprice > 50000
LEFT JOIN 
    RankedSuppliers RS ON RS s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_type LIKE '%deluxe%'
        )
    )
WHERE 
    EO.item_count > 5
ORDER BY 
    r.r_name, EO.total_revenue DESC;
