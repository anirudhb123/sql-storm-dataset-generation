WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice * (1 - l.l_discount) AS net_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
)
SELECT 
    o.o_orderkey,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    COUNT(DISTINCT CASE WHEN li.l_returnflag = 'R' THEN li.l_orderkey END) AS returned_items,
    SUM(li.net_price) AS total_net_price,
    RANK() OVER (ORDER BY SUM(li.net_price) DESC) AS revenue_rank,
    sd.s_name AS supplier_name,
    sd.total_supply_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    customer c ON ro.o_custkey = c.c_custkey
JOIN 
    FilteredLineItems li ON ro.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON li.l_suppkey = sd.s_suppkey
WHERE 
    ro.price_rank <= 5
GROUP BY 
    o.o_orderkey, c.c_name, sd.s_name, sd.total_supply_cost
ORDER BY 
    total_net_price DESC;
