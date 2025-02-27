WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
), 
SupplierAggregates AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        supplier s
    JOIN 
        SupplierAggregates sa ON s.s_suppkey = sa.ps_suppkey
    WHERE 
        sa.total_supply_value > 50000
)
SELECT 
    c.co_name,
    COALESCE(HVS.s_name, 'No Supplier') AS supplier_name,
    COALESCE(ro.o_orderkey, 0) AS order_key,
    ro.o_totalprice,
    CASE 
        WHEN ro.o_orderkey IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    CustomerOrders c
LEFT JOIN 
    HighValueSuppliers HVS ON c.c_custkey = HVS.s_suppkey
LEFT JOIN 
    RankedOrders ro ON c.c_custkey = ro.o_orderkey
ORDER BY 
    c.total_spent DESC NULLS LAST,
    HVS.s_name ASC,
    ro.o_totalprice DESC NULLS FIRST;
