WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierPartSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    INNER JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.supplier_rank = 1
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sp.total_available, 0) AS total_available,
    COALESCE(sp.total_cost, 0.00) AS total_cost,
    COALESCE(os.total_revenue, 0.00) AS total_revenue,
    CASE
        WHEN os.item_count < 5 THEN 'Low Volume'
        WHEN os.item_count BETWEEN 5 AND 15 THEN 'Medium Volume'
        ELSE 'High Volume'
    END AS volume_category,
    CASE
        WHEN os.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed'
    END AS order_status
FROM 
    part p
LEFT JOIN 
    SupplierPartSummary sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o
        WHERE o.o_orderkey = ANY (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
    )
WHERE 
    (p.p_size BETWEEN 1 AND 20 OR p.p_container IS NULL)
    AND (p.p_retailprice IS NOT NULL OR p.p_comment LIKE '%special%')
ORDER BY 
    p.p_partkey DESC,
    total_revenue DESC,
    order_status;
