WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        (l.l_extendedprice * (1 - l.l_discount)) AS discount_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
), RankedOrders AS (
    SELECT 
        oli.o_orderkey,
        oli.o_orderdate,
        SUM(oli.discount_price) AS total_discount_price,
        ROW_NUMBER() OVER (PARTITION BY oli.o_orderkey ORDER BY oli.o_orderdate DESC) AS order_rank
    FROM 
        OrderLineItems oli
    GROUP BY 
        oli.o_orderkey, oli.o_orderdate
)

SELECT 
    rp.s_suppkey,
    rp.s_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(rp.ps_supplycost * sub.l_quantity) AS total_supplycost,
    AVG(ro.total_discount_price) AS avg_discount_price
FROM 
    SupplierParts rp
JOIN 
    RankedOrders ro ON rp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
LEFT JOIN 
    lineitem sub ON ro.o_orderkey = sub.l_orderkey
GROUP BY 
    rp.s_suppkey, rp.s_name
ORDER BY 
    total_orders DESC, total_supplycost DESC
LIMIT 10;
