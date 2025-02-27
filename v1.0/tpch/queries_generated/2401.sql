WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate >= DATE '2023-01-01'
        AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, c.c_custkey
),
RankedOrders AS (
    SELECT 
        co.c_custkey,
        co.o_orderkey,
        co.total_order_value,
        ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.total_order_value DESC) AS order_rank
    FROM 
        CustomerOrders co
),
TopCustomerOrders AS (
    SELECT 
        ro.c_custkey,
        ro.o_orderkey,
        ro.total_order_value
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(COALESCE(sc.total_supply_cost, 0)) AS total_supplier_cost
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        SupplierCosts sc ON n.n_nationkey = sc.s_suppkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    r.r_name,
    rs.nation_count,
    rs.total_supplier_cost,
    COALESCE(SUM(tco.total_order_value), 0) AS total_order_value
FROM 
    region r
JOIN 
    RegionStats rs ON r.r_regionkey = rs.r_regionkey
LEFT JOIN 
    TopCustomerOrders tco ON r.r_regionkey = (SELECT n.r_regionkey FROM nation n WHERE n.n_nationkey = tco.c_custkey)
GROUP BY 
    r.r_name, rs.nation_count, rs.total_supplier_cost
ORDER BY 
    r.r_name;
