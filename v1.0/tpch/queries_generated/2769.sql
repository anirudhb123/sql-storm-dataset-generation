WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
PartQuantities AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS average_discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2022-01-01' 
        AND l.l_shipdate < '2023-01-01'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    pq.total_quantity,
    pq.average_discount,
    s.s_name,
    s.total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'O') AS open_orders_count,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus <> 'O') AS closed_orders_count
FROM 
    part p
LEFT JOIN 
    PartQuantities pq ON p.p_partkey = pq.l_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = p.p_partkey
        ORDER BY ps.ps_supplycost DESC
        LIMIT 1
    )
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = l.l_orderkey
GROUP BY 
    p.p_name, p.p_brand, pq.total_quantity, pq.average_discount, s.s_name, s.total_supply_cost 
HAVING 
    SUM(pq.total_quantity) IS NOT NULL
ORDER BY 
    total_quantity DESC, average_discount ASC;
