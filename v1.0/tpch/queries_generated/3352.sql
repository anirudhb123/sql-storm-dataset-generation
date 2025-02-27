WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(DISTINCT l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate >= DATEADD(day, -30, CURRENT_DATE)
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(SUM(SU.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(SUM(OD.total_price_after_discount), 0) AS total_order_revenue,
    COUNT(OD.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COALESCE(SU.total_supply_cost, 0) DESC) AS rn_supplier_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierSummary SU ON n.n_nationkey = SU.s_nationkey
LEFT JOIN 
    OrderDetails OD ON n.n_nationkey = OD.c_nationkey
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    COUNT(DISTINCT OD.o_orderkey) > 5
ORDER BY 
    r.r_name, total_order_revenue DESC;
