
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        AVG(s.s_acctbal) AS average_balance,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
NationSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    R.n_name,
    COALESCE(S.total_value, 0) AS total_supplier_value,
    COALESCE(R.supplier_count, 0) AS total_suppliers,
    AVG(S.average_balance) AS avg_supplier_balance,
    COUNT(DISTINCT O.o_orderkey) AS total_recent_orders,
    SUM(O.total_revenue) AS total_recent_revenue
FROM 
    NationSuppliers R
LEFT JOIN 
    SupplierStats S ON R.n_nationkey = S.s_suppkey
LEFT JOIN 
    RecentOrders O ON R.n_nationkey = (SELECT n.n_nationkey FROM customer c JOIN nation n ON c.c_nationkey = n.n_nationkey WHERE c.c_custkey = O.o_custkey)
GROUP BY 
    R.n_name, S.total_value, R.supplier_count
HAVING 
    SUM(O.total_revenue) > 1000000
ORDER BY 
    total_supplier_value DESC,
    R.n_name;
