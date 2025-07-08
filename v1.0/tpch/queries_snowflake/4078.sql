WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name AS nation_name,
    COALESCE(ps.total_sales, 0) AS total_supplier_sales,
    COALESCE(co.total_spent, 0) AS total_customer_spent,
    ps.total_sales - COALESCE(co.total_spent, 0) AS profit_loss
FROM 
    nation ns
LEFT JOIN 
    SupplierSales ps ON ns.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ps.s_suppkey)
LEFT JOIN 
    CustomerOrders co ON ns.n_nationkey = (SELECT c_nationkey FROM customer WHERE c_custkey = co.c_custkey)
WHERE 
    ns.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'Europe')
ORDER BY 
    profit_loss DESC, nation_name;