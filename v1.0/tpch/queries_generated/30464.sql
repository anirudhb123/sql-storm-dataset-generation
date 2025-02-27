WITH RECURSIVE OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey,
        o.o_custkey
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(ot.total_price), 0) AS customer_total
    FROM 
        customer c
    LEFT JOIN 
        OrderTotals ot ON c.c_custkey = ot.o_orderkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, 
        c.c_name
), 
NationSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, 
        n.n_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COALESCE(hv.customer_total, 0) AS total_spent,
    ns.supplier_count AS total_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    HighValueCustomers hv ON n.n_nationkey = hv.c_nationkey
LEFT JOIN 
    NationSuppliers ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    (total_spent > 5000 OR total_suppliers > 10)
ORDER BY 
    total_spent DESC, 
    total_suppliers DESC;
