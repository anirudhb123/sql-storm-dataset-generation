WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
QualifiedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS account_rank
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -3, GETDATE())
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    r.r_name AS Region_Name,
    COALESCE(qq.total_revenue, 0) AS Total_Revenue,
    ss.total_supply_cost AS Total_Supply_Cost,
    ss.supply_rank AS Supplier_Rank,
    cc.account_rank AS Customer_Rank,
    CASE 
        WHEN qq.total_revenue > 10000 THEN 'High Value'
        WHEN qq.total_revenue BETWEEN 5000 AND 10000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS Revenue_Category
FROM SupplierStats ss
JOIN nation n ON ss.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN QualifiedCustomers cc ON cc.c_custkey = (
    SELECT TOP 1 o.o_custkey 
    FROM RecentOrders qq 
    WHERE qq.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderdate DESC
    )
    ORDER BY qq.total_revenue DESC
)
LEFT JOIN RecentOrders qq ON ss.s_suppkey = qq.o_custkey
WHERE ss.total_supply_cost IS NOT NULL
ORDER BY ss.total_supply_cost DESC, cc.account_rank ASC;
