WITH SupplierSummary AS (
    SELECT 
        s.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.n_nationkey
),

OrderLineItemSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(*) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),

CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.r_regionkey,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)

SELECT 
    cr.region_name,
    ss.n_nationkey,
    COALESCE(SUM(oss.total_price), 0) AS total_order_value,
    COALESCE(SUM(ss.total_cost), 0) AS total_supplier_cost,
    MAX(ss.avg_account_balance) AS max_supplier_balance
FROM 
    CustomerRegion cr
LEFT JOIN 
    OrderLineItemSummary oss ON cr.c_custkey = oss.o_orderkey
LEFT JOIN 
    SupplierSummary ss ON cr.r_regionkey = ss.n_nationkey
WHERE 
    cr.region_name IS NOT NULL
GROUP BY 
    cr.region_name, ss.n_nationkey
HAVING 
    COALESCE(SUM(oss.total_price), 0) > 10000
ORDER BY 
    cr.region_name ASC, max_supplier_balance DESC;
