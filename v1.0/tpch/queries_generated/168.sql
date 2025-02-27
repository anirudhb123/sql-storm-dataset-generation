WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        od.o_orderkey, 
        od.total_order_value,
        RANK() OVER (ORDER BY od.total_order_value DESC) AS order_rank
    FROM 
        OrderDetails od
),
RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_order_value,
        ro.order_rank,
        EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM o.o_orderdate) AS order_age
    FROM 
        RankedOrders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
),
Summary AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT c.c_custkey) AS customer_count, 
        SUM(COALESCE(ss.total_avail_qty, 0)) AS total_avail_qty,
        AVG(COALESCE(ss.avg_supply_cost, 0)) AS avg_supply_cost,
        SUM(COALESCE(ro.total_order_value, 0)) AS total_sales,
        COUNT(DISTINCT ro.o_orderkey) AS order_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        SupplierStats ss ON c.c_nationkey = ss.s_suppkey
    LEFT JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    s.r_name,
    s.customer_count,
    s.total_avail_qty,
    s.avg_supply_cost,
    s.total_sales,
    s.order_count,
    CASE 
        WHEN s.order_count > 0 THEN s.total_sales / s.order_count 
        ELSE 0 
    END AS avg_order_value
FROM 
    Summary s
WHERE 
    s.total_sales <> 0
ORDER BY 
    s.total_sales DESC;
