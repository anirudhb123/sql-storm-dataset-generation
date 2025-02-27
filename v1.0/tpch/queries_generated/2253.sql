WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierNation AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    sn.supplier_count,
    sn.avg_balance,
    COALESCE(hv.total_orders, 0) AS high_value_order_count,
    ROUND((sn.avg_balance * 1.1), 2) AS adjusted_avg_balance
FROM 
    region r
LEFT JOIN 
    SupplierNation sn ON sn.n_name = r.r_name
LEFT JOIN 
    HighValueCustomers hv ON hv.c_name LIKE '%' || r.r_name || '%'
UNION ALL
SELECT 
    'Total' AS r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_balance,
    COUNT(1) AS high_value_order_count,
    ROUND(AVG(s.s_acctbal) * 1.1, 2) AS adjusted_avg_balance
FROM 
    supplier s
JOIN 
    HighValueCustomers hv ON hv.c_name LIKE '%' || s.s_name || '%'
GROUP BY 
    s.s_nationkey
ORDER BY 
    r_name;
