WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    ps.total_available_qty,
    co.order_count,
    co.total_spent,
    rnk,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.order_count > 0 THEN 'Valued Customer'
        ELSE 'Inactive Customer'
    END AS customer_status
FROM 
    part p
LEFT JOIN 
    PartSupplierSummary ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal = (
        SELECT MAX(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = (
            SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'CANADA'
        )
    ))
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (
        SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey
    )
ORDER BY 
    p.p_partkey, co.total_spent DESC NULLS LAST;
