WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE 
        ps.ps_availqty > 100
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
FilteredCustomerOrders AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        ord.total_revenue,
        cus.c_acctbal
    FROM 
        RankedCustomers cus
    JOIN 
        CustomerOrderSummary ord ON cus.c_custkey = ord.o_custkey
    WHERE 
        cus.rank <= 5 AND 
        ord.total_revenue > 1000
)
SELECT 
    DISTINCT cf.c_name,
    (SELECT COUNT(*)
     FROM lineitem l
     WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cf.c_custkey)) AS total_lineitems,
    (SELECT AVG(total_cost) 
     FROM HighValueSuppliers hvs) AS avg_supplier_cost,
    COALESCE((
        SELECT COUNT(*)
        FROM region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        WHERE n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s)
    ), 0) AS supplier_nation_count
FROM 
    FilteredCustomerOrders cf
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cf.c_custkey)
WHERE 
    cf.c_acctbal IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE s.s_nationkey = cf.c_custkey
    )
ORDER BY 
    cf.total_revenue DESC, cf.c_name ASC;
