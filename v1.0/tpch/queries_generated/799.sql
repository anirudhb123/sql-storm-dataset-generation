WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
),
FinalReport AS (
    SELECT 
        c.c_name AS customer_name,
        COALESCE(so.total_price, 0) AS last_order_value,
        COALESCE(si.total_available, 0) AS total_available_inventory,
        COUNT(DISTINCT ro.o_orderkey) AS total_orders,
        r.r_name AS region_name
    FROM 
        CustomerOrders co
    JOIN 
        RankedOrders ro ON co.c_custkey = ro.o_custkey
    LEFT JOIN 
        SupplierInfo si ON ro.o_orderkey IN (
            SELECT l.l_orderkey 
            FROM lineitem l 
            WHERE l.l_quantity > 0
        )
    JOIN 
        TopRegions tr ON tr.total_orders > 0
    JOIN 
        nation n ON n.n_nationkey = co.c_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank = 1 AND 
        co.total_spent > (
            SELECT AVG(total_spent) FROM CustomerOrders
        )
    GROUP BY 
        c.c_name, ro.total_price, si.total_available, r.r_name
)
SELECT 
    customer_name,
    last_order_value,
    total_available_inventory,
    total_orders,
    region_name
FROM 
    FinalReport
ORDER BY 
    total_available_inventory DESC, last_order_value ASC;
