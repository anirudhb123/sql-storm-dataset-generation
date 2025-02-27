WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -12, GETDATE())
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_retailprice,
    p.p_size,
    (CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Active Customer'
     END) AS customer_status,
    COALESCE(sp.total_supply_cost, 0) AS supplier_cost,
    ro.o_orderstatus,
    ro.o_orderdate,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
FROM 
    part p
LEFT JOIN 
    CustomerSummary cs ON p.p_partkey = cs.c_custkey
LEFT JOIN 
    SupplierPerformance sp ON p.p_partkey = sp.part_count
LEFT JOIN 
    RankedOrders ro ON ro.rank_order <= 10 AND ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
WHERE 
    (p.p_retailprice > 50 OR p.p_size < 10)
    AND (p.p_brand LIKE 'A%' OR p.p_mfgr NOT IN (SELECT s.s_mfgr FROM suppliers s WHERE s.s_acctbal < 100))
ORDER BY 
    rank_price, supplier_cost DESC;
