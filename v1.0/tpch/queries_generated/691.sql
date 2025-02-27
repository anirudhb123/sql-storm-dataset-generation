WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    ns.n_name AS nation_name,
    ss.s_name AS supplier_name,
    ss.total_available_qty,
    os.line_item_count,
    os.total_sales,
    cp.total_orders,
    cp.total_spent,
    cp.last_order_date
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.order_rank <= 10
LEFT JOIN 
    CustomerPurchases cp ON cp.total_orders > 5
WHERE 
    (ss.total_supply_cost > 10000 OR cp.total_spent IS NULL)
ORDER BY 
    ss.total_available_qty DESC, cp.total_spent DESC;
