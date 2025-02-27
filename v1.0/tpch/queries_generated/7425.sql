WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER(PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
SupplierAggregates AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 20
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    sa.total_supply_cost,
    sa.supplier_count
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierAggregates sa ON ro.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey LIMIT 1)
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, 
    sa.total_supply_cost DESC;
