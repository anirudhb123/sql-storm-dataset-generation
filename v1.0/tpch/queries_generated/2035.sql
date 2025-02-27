WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
OrdersWithHighValueParts AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS high_value_part_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_partkey IN (SELECT p.p_partkey FROM part p)
    GROUP BY 
        o.o_orderkey
),
FinalReport AS (
    SELECT 
        r.r_name,
        ns.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.total_price) AS total_revenue,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation ns ON r.r_regionkey = ns.n_regionkey
    LEFT JOIN 
        customer c ON ns.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
    LEFT JOIN 
        HighValueParts hvp ON l.l_partkey = hvp.ps_partkey
    WHERE 
        (rs.rn <= 5 OR hvp.total_supply_cost IS NOT NULL)
    GROUP BY 
        r.r_name, ns.n_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COALESCE(fr.order_count, 0) AS total_orders,
    COALESCE(fr.total_revenue, 0) AS total_revenue,
    COALESCE(fr.total_supplier_balance, 0) AS total_supplier_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    FinalReport fr ON r.r_name = fr.region AND n.n_name = fr.nation
ORDER BY 
    region, nation;
