
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 0 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 50 AND 
        (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL)
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > DATE '1997-01-01'
)
SELECT 
    s.s_name,
    s.total_available_quantity,
    s.total_supply_cost,
    c.c_name AS customer_name,
    c.order_count,
    c.total_order_value,
    COALESCE(SUM(r.l_discount), 0) AS total_discount_received
FROM 
    SupplierInfo s
LEFT JOIN 
    CustomerOrders c ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps
        WHERE ps.ps_partkey IN (SELECT r.l_partkey FROM RankedItems r WHERE r.item_rank = 1)
        LIMIT 1
    )
LEFT JOIN 
    RankedItems r ON r.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
GROUP BY 
    s.s_name, s.total_available_quantity, s.total_supply_cost, c.c_name, c.order_count, c.total_order_value
ORDER BY 
    s.total_available_quantity DESC, c.total_order_value DESC;
