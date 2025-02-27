WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineItem AS (
    SELECT 
        o.o_orderkey,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned_price,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    cs.c_name,
    cs.total_spent,
    ss.s_name AS supplier_name,
    ss.total_available,
    ss.total_cost,
    ol.total_sales,
    ol.total_returned_price,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS rank_order
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON cs.order_count > 5
LEFT JOIN 
    OrderLineItem ol ON EXISTS (
        SELECT 1
        FROM order_lineitem oli
        WHERE oli.o_orderkey = ol.o_orderkey AND ol.total_sales > 10000
    )
WHERE 
    cs.total_spent IS NOT NULL
ORDER BY 
    cs.total_spent DESC NULLS LAST
LIMIT 100;
