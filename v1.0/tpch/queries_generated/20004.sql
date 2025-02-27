WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE()) 
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 100
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS balance_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_container,
    COALESCE(SUM(l.l_extendedprice*(1-l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS order_status
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey 
LEFT JOIN 
    SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN 
    supplier s ON sa.ps_suppkey = s.s_suppkey
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM HighValueCustomers h
        WHERE h.c_custkey = o.o_custkey 
        AND h.balance_rank <= 10
    )
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_container
HAVING 
    total_revenue > (SELECT AVG(total_revenue) FROM (
        SELECT 
            COALESCE(SUM(l2.l_extendedprice*(1-l2.l_discount)), 0) AS total_revenue
        FROM 
            lineitem l2
        JOIN 
            orders o2 ON l2.l_orderkey = o2.o_orderkey
        GROUP BY 
            o2.o_orderkey
    ) avg_revenue)
ORDER BY 
    total_revenue DESC, order_status ASC;
