WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
), 
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), 
SupplierPerformance AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_sales
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    CASE 
        WHEN MAX(tp.total_spent) IS NULL THEN 'No Customers'
        ELSE MAX(tp.total_spent::decimal) 
    END AS max_customer_spent
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPerformance sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    TopCustomers tp ON tp.c_custkey = s.s_suppkey
WHERE 
    s.s_acctbal IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(sp.supplier_sales) > 50000 OR MAX(tp.total_spent) IS NOT NULL
ORDER BY 
    nation_count DESC, total_supply_cost ASC;
