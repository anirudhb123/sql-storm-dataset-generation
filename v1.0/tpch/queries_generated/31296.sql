WITH RECURSIVE CTE_OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CTE_SupplierRevenue AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, s.s_suppkey
),
CTE_AggNation AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    COALESCE(SUM(o.total_revenue), 0) AS total_revenue,
    COALESCE(AVG(sr.supplier_revenue), 0) AS avg_supplier_revenue,
    COALESCE(na.total_acctbal, 0) AS total_acctbal,
    na.total_suppliers,
    (SELECT COUNT(*) FROM orders WHERE o_orderstatus = 'O') AS open_orders_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CTE_OrderDetails o ON o.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o.o_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = n.n_nationkey))
LEFT JOIN 
    CTE_SupplierRevenue sr ON sr.supplier_revenue IN (SELECT SUM(supplier_revenue) FROM CTE_SupplierRevenue WHERE p.p_partkey IN (SELECT DISTINCT ps_partkey FROM partsupp WHERE ps_availqty > 0))
LEFT JOIN 
    CTE_AggNation na ON na.n_name = n.n_name
WHERE
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, na.total_acctbal, na.total_suppliers
HAVING 
    SUM(o.total_revenue) > 100000
ORDER BY 
    region_name;
