WITH RankedSales AS (
    SELECT 
        ps.partkey,
        ps.suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.partkey, ps.suppkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(fs.s_name, 'No Supplier') AS supplier_name,
        cs.c_name AS customer_name,
        cs.total_order_value,
        rs.total_revenue,
        rs.revenue_rank
    FROM 
        part p
    LEFT JOIN 
        RankedSales rs ON p.p_partkey = rs.partkey AND rs.revenue_rank = 1
    LEFT JOIN 
        FilteredSuppliers fs ON rs.suppkey = fs.s_suppkey
    LEFT JOIN 
        CustomerOrders cs ON cs.order_count > 5
    WHERE 
        p.p_retailprice BETWEEN 10 AND 500
)
SELECT 
    f.partkey,
    f.p_name,
    f.supplier_name,
    f.customer_name,
    f.total_order_value,
    f.total_revenue
FROM 
    FinalResults f
WHERE 
    f.total_revenue IS NOT NULL
ORDER BY 
    f.total_order_value DESC, f.total_revenue ASC
LIMIT 100;
