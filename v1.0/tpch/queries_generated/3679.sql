WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
AggregateLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(DISTINCT l.l_partkey) AS total_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(a.total_price_after_discount, 0) AS total_price,
    s.total_supply_cost AS supplier_cost,
    COUNT(DISTINCT c.c_custkey) AS total_customers_served
FROM 
    RankedOrders r
LEFT JOIN 
    AggregateLineItems a ON r.o_orderkey = a.l_orderkey
LEFT JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey))
LEFT JOIN 
    customer c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = r.o_orderkey)
WHERE
    r.rn <= 10
GROUP BY 
    r.o_orderkey, r.o_orderdate, s.total_supply_cost
ORDER BY 
    r.o_orderdate DESC, total_price DESC;
