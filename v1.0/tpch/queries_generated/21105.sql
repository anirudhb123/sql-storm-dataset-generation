WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_brand,
        p.p_retailprice
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (
            SELECT 
                AVG(p2.p_retailprice) 
            FROM 
                part p2 
            WHERE 
                p2.p_type LIKE '%fragile%'
        )
),
AggregatedOrders AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS line_item_count,
        SUM(l.l_tax) AS total_tax
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '90 days' AND CURRENT_DATE
    GROUP BY 
        l.l_orderkey
)

SELECT 
    s.s_name AS supplier_name,
    ns.n_name AS supplier_nation,
    pp.p_brand AS part_brand,
    pp.ps_availqty AS available_quantity,
    c.c_name AS customer_name,
    hvc.total_spent AS customer_spending,
    ao.total_revenue AS order_revenue,
    ao.line_item_count,
    COALESCE(MAX(r.rank_by_balance), 0) AS supplier_rank,
    CASE 
        WHEN ao.line_item_count IS NULL THEN 'No Orders' 
        ELSE 'Orders Present' 
    END AS order_status
FROM 
    PartSupplierDetails pp
LEFT JOIN 
    RankedSuppliers r ON pp.ps_suppkey = r.s_suppkey
LEFT JOIN 
    supplier s ON pp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_custkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey IN (
            SELECT l.l_orderkey 
            FROM lineitem l 
            WHERE l.l_partkey = pp.ps_partkey
        )
    )
LEFT JOIN 
    AggregatedOrders ao ON ao.l_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = pp.ps_partkey
    )
WHERE 
    pp.ps_availqty > 0
ORDER BY 
    customer_spending DESC NULLS LAST, supplier_rank DESC;
