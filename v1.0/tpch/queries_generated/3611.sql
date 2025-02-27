WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
NationInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    ns.n_name AS nation_name,
    ns.region_name,
    COALESCE(st.total_avail_qty, 0) AS total_available_quantity,
    COALESCE(st.avg_supply_cost, 0) AS average_supply_cost,
    customer.c_name AS customer_name,
    od.total_price AS latest_order_total,
    od.o_orderdate AS latest_order_date
FROM 
    NationInfo ns
LEFT JOIN 
    SupplierStats st ON ns.total_suppliers > 0 AND st.part_count > 0
LEFT JOIN 
    customer ON ns.n_nationkey = customer.c_nationkey
LEFT JOIN 
    OrderDetails od ON customer.c_custkey = od.o_orderkey
WHERE 
    od.order_rank = 1 AND 
    (od.total_price > 1000 OR st.avg_supply_cost IS NULL)
ORDER BY 
    ns.n_name, od.total_price DESC;
