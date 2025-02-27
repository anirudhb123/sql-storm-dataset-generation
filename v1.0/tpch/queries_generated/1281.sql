WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartSupplierCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
    HAVING 
        total_order_value > 10000
)
SELECT 
    po.p_name,
    ps.total_available,
    ss.avg_supply_cost,
    rh.o_orderdate,
    rh.total_order_value
FROM 
    PartSupplierCTE po
LEFT JOIN 
    SupplierStats ps ON po.supplier_count < ps.total_available
LEFT JOIN 
    RankedOrders rh ON po.p_partkey = rh.o_orderkey
LEFT JOIN 
    HighValueOrders hv ON rh.o_orderkey = hv.o_orderkey
WHERE 
    ps.total_available IS NOT NULL
    AND hv.total_order_value IS NOT NULL
ORDER BY 
    rh.o_orderdate DESC, ps.avg_supply_cost ASC;
