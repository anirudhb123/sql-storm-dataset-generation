WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_sold,
        MAX(l.l_shipdate) AS last_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1996-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(cs.total_spent), 0) AS total_customer_spent,
    COUNT(DISTINCT ss.ps_partkey) AS distinct_parts_supplied,
    SUM(ss.total_available_quantity) AS total_available_quantity
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSummary ss ON ss.ps_suppkey = s.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderstatus = 'O'
    )
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
WHERE 
    r.r_name LIKE '%East%'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC, total_customer_spent DESC;