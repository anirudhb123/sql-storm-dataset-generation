WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
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
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.total_price) AS total_spent
    FROM 
        customer c
    JOIN 
        OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(od.total_price) > 50000
),
SupplierRankings AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_avail_qty,
        ss.avg_supply_cost,
        RANK() OVER (ORDER BY ss.total_avail_qty DESC) AS rank_by_quantity,
        RANK() OVER (ORDER BY ss.avg_supply_cost ASC) AS rank_by_cost
    FROM 
        SupplierSummary ss
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(*) OVER (PARTITION BY c.c_custkey) AS line_item_count,
    COALESCE(sr.rank_by_quantity, 0) AS supplier_quantity_rank,
    COALESCE(sr.rank_by_cost, 0) AS supplier_cost_rank
FROM 
    HighValueCustomers c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierRankings sr ON l.l_suppkey = sr.s_suppkey
WHERE 
    o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
GROUP BY 
    c.c_name, s.s_name, sr.rank_by_quantity, sr.rank_by_cost
ORDER BY 
    total_order_value DESC, customer_name, supplier_name;
