WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RegionSupplier AS (
    SELECT 
        r.r_name,
        s.s_name,
        s.s_phone,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_name, s.s_phone
)
SELECT 
    rs.r_name,
    rs.s_name,
    rs.s_phone,
    COALESCE(ss.total_available_quantity, 0) AS available_qty,
    COALESCE(os.total_revenue, 0) AS order_revenue,
    ss.avg_account_balance,
    rs.total_supply_cost
FROM 
    RegionSupplier rs
LEFT JOIN 
    SupplierSummary ss ON rs.s_name = ss.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = (SELECT MAX(o_orderkey) FROM orders)
ORDER BY 
    rs.r_name, ss.avg_account_balance DESC;
