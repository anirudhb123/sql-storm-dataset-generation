WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        partsupp ps
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierStats AS (
    SELECT 
        n.n_name AS nation_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    c.c_name,
    COALESCE(o.total_spent, 0) AS total_spent,
    COALESCE(o.order_count, 0) AS order_count,
    COALESCE(REPLACE(CAST(o.avg_order_value AS VARCHAR), '.00', ''), '0') AS avg_order_value,
    s.nation_name,
    s.supplier_count,
    s.total_account_balance,
    ps.p_name, 
    ps.p_retailprice,
    CASE 
        WHEN ps.p_retailprice < (SELECT AVG(p.p_retailprice) FROM part p) THEN 'Below Average' 
        ELSE 'Above Average' 
    END AS price_comparison
FROM 
    customerOrderSummary o
FULL OUTER JOIN 
    Customer c ON o.c_custkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.ps_suppkey = c.c_custkey AND rs.rank = 1
LEFT JOIN 
    part ps ON ps.p_partkey = rs.ps_partkey
LEFT JOIN 
    SupplierStats s ON s.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = c.c_nationkey)
ORDER BY 
    o.total_spent DESC, 
    s.supplier_count DESC, 
    c.c_name;
