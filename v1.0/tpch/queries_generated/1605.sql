WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        ro.total_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    WHERE 
        ro.revenue_rank <= 10
),
SupplierRevenue AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * li.l_quantity) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_custkey,
        c.c_name,
        COUNT(li.l_orderkey) AS item_count,
        SUM(li.l_extendedprice) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name
)
SELECT 
    cu.c_name,
    cu.total_revenue,
    sr.s_name AS supplier_name,
    sr.total_supply_cost,
    cod.item_count,
    cod.total_lineitem_value
FROM 
    TopCustomers cu
LEFT JOIN 
    SupplierRevenue sr ON sr.total_supply_cost IS NOT NULL
JOIN 
    CustomerOrders cod ON cu.c_custkey = cod.c_custkey
WHERE 
    cu.total_revenue > (SELECT AVG(total_revenue) FROM TopCustomers)
ORDER BY 
    cu.total_revenue DESC, sr.total_supply_cost ASC;
