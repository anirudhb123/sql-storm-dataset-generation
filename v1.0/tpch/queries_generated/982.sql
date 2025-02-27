WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        os.total_revenue,
        os.supplier_count,
        o.o_orderstatus,
        o.o_orderpriority
    FROM 
        OrderSummary os
    JOIN 
        orders o ON os.o_orderkey = o.o_orderkey
    WHERE 
        os.order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name
)
SELECT 
    to.o_orderkey,
    to.total_revenue,
    to.supplier_count,
    to.o_orderstatus,
    CASE 
        WHEN to.o_orderpriority LIKE 'high%' THEN 'High Priority'
        WHEN to.o_orderpriority LIKE 'low%' THEN 'Low Priority'
        ELSE 'Normal Priority'
    END AS priority_class,
    COALESCE(pd.total_supply_cost, 0) AS supplier_total_cost
FROM 
    TopOrders to
LEFT JOIN 
    SupplierDetails pd ON to.o_orderkey = pd.ps_partkey -- Example of a mismatched join for NULL logic
WHERE 
    (to.total_revenue > 1000 OR to.supplier_count > 5)
ORDER BY 
    to.total_revenue DESC, to.o_orderkey ASC;
