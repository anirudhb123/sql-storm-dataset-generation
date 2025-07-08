
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(COALESCE(o.o_orderdate, '1900-01-01')) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL)
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name,
    ns.region_name,
    rs.s_name AS top_supplier,
    cs.total_spent,
    cs.total_orders,
    COALESCE(lds.net_revenue, 0) AS total_revenue,
    CASE 
        WHEN cs.last_order_date > DATE '1998-10-01' - INTERVAL '1 year' THEN 'Active' 
        ELSE 'Inactive' 
    END AS customer_status
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    NationRegion ns ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey LIMIT 1)
LEFT JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey AND rs.rn = 1
LEFT JOIN 
    LineItemDetails lds ON lds.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
ORDER BY 
    cs.total_spent DESC,
    customer_status;
