
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
        )
), SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    INNER JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
    WHERE 
        s.s_acctbal > 1000 
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        c.c_acctbal IS NOT NULL 
    GROUP BY 
        c.c_custkey
), CombinedData AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        cp.total_spent,
        sp.total_avail_qty,
        CASE
            WHEN cp.order_count > 10 THEN 'Frequent Shopper'
            WHEN cp.total_spent IS NULL THEN 'No Spend'
            ELSE 'Occasional Shopper'
        END AS customer_category
    FROM 
        RankedOrders ro
    LEFT JOIN 
        CustomerSpending cp ON ro.o_orderkey = cp.c_custkey
    LEFT JOIN 
        SupplierParts sp ON ro.o_orderkey = sp.ps_partkey
)
SELECT 
    cd.customer_category,
    COUNT(*) AS num_orders,
    AVG(cd.o_totalprice) AS avg_order_value,
    SUM(COALESCE(cd.total_avail_qty, 0)) AS total_available_qty,
    STRING_AGG(cd.o_orderdate::TEXT, ', ') AS order_dates
FROM 
    CombinedData cd
GROUP BY 
    cd.customer_category
HAVING 
    SUM(COALESCE(cd.total_avail_qty, 0)) > 0 
    AND COUNT(*) > 5
ORDER BY 
    num_orders DESC, avg_order_value DESC;
