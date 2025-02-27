WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_acctbal,
        COALESCE(SUM(l.l_extendedprice), 0) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank_acctbal
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_acctbal
),
SupplierSales AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.supplier_revenue,
        ROW_NUMBER() OVER (ORDER BY ss.supplier_revenue DESC) AS rn_supplier
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.ps_suppkey
)
SELECT 
    CASE 
        WHEN cd.order_count > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buyer_type,
    COUNT(DISTINCT cd.c_custkey) AS number_of_customers,
    SUM(cd.total_spent) AS total_revenue,
    MAX(ts.supplier_revenue) AS top_supplier_revenue
FROM 
    CustomerDetails cd
FULL OUTER JOIN 
    TopSuppliers ts ON cd.c_custkey = (SELECT TOP 1 c.c_custkey FROM customer c ORDER BY c.c_acctbal DESC)
WHERE 
    cd.total_spent IS NOT NULL OR ts.supplier_revenue IS NOT NULL
GROUP BY 
    buyer_type
HAVING 
    COUNT(DISTINCT cd.c_custkey) > 5
ORDER BY 
    total_revenue DESC;
