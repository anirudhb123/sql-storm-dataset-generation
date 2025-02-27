WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' 
        AND o.o_orderdate < CURRENT_DATE
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartAggregates AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_price,
        COUNT(DISTINCT l.l_orderkey) AS total_orders,
        MAX(l.l_discount) AS max_discount
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_name,
    pa.total_quantity,
    pa.avg_price,
    pa.max_discount,
    COALESCE(c.order_count, 0) AS customer_order_count,
    CASE 
        WHEN o.rnk <= 5 THEN 'Top Orders'
        ELSE 'Other Orders'
    END AS order_ranking
FROM 
    PartAggregates pa
JOIN 
    RankedOrders o ON pa.total_orders = o.o_orderkey
LEFT JOIN 
    CustomerDetails c ON pa.total_orders = c.c_custkey
WHERE 
    pa.avg_price < (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND pa.max_discount IS NOT NULL
ORDER BY 
    pa.total_quantity DESC, 
    o.o_totalprice ASC
LIMIT 100
OFFSET 0;
