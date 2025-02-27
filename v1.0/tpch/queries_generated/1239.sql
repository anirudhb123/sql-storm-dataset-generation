WITH SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
), CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(od.total_order_value) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        OrderDetails od ON c.c_custkey = od.o_custkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
), NationSupplierCount AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    cm.c_name AS customer_name,
    cm.total_orders,
    cm.avg_order_value,
    sm.total_parts,
    sm.total_value,
    nsc.supplier_count,
    CASE 
        WHEN cm.avg_order_value IS NULL THEN 'No Orders'
        WHEN cm.avg_order_value > 5000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    CustomerOrderStats cm
JOIN 
    SupplierMetrics sm ON sm.avg_account_balance > 5000
JOIN 
    nation n ON n.n_nationkey = (
        SELECT n_nationkey 
        FROM nation 
        WHERE n_name = (
            SELECT n_name 
            FROM nation 
            WHERE EXISTS (
                SELECT 1 
                FROM supplier s 
                WHERE s.s_nationkey = n.n_nationkey AND s.s_acctbal > 1000
            ) 
            LIMIT 1
        )
    )
JOIN 
    NationSupplierCount nsc ON nsc.n_name = n.n_name
WHERE 
    nsc.supplier_count > 5
ORDER BY 
    cm.avg_order_value DESC;
