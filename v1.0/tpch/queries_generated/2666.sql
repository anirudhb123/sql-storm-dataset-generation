WITH SupplierAggregate AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        sa.total_supply_cost,
        sa.total_orders,
        RANK() OVER (ORDER BY sa.total_supply_cost DESC) AS rank
    FROM 
        SupplierAggregate sa
    JOIN 
        supplier s ON sa.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_name,
    ts.total_supply_cost,
    ts.total_orders,
    CASE 
        WHEN ts.total_orders > 100 THEN 'High volume'
        WHEN ts.total_orders BETWEEN 50 AND 100 THEN 'Medium volume'
        ELSE 'Low volume'
    END AS order_volume_category
FROM 
    TopSuppliers ts
WHERE 
    ts.rank <= 10 OR ts.total_supply_cost > 10000
ORDER BY 
    ts.total_supply_cost DESC;

WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_name,
    pd.supplier_count,
    pd.total_avail_qty,
    CASE 
        WHEN pd.total_avail_qty IS NULL THEN 'No Supply'
        WHEN pd.total_avail_qty < 10 THEN 'Low Availability'
        ELSE 'Available'
    END AS availability_status
FROM 
    PartDetails pd
JOIN 
    part p ON pd.p_partkey = p.p_partkey
WHERE 
    p.p_size > 10
ORDER BY 
    availability_status DESC, pd.total_avail_qty;
