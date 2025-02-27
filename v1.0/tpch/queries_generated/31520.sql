WITH RECURSIVE PurchaseHistory AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        total_spent > 1000
    UNION ALL
    SELECT 
        ph.c_custkey, 
        ph.c_name, 
        ph.total_spent + SUM(o.o_totalprice) 
    FROM 
        PurchaseHistory ph 
    JOIN 
        orders o ON ph.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        ph.c_custkey, ph.c_name, ph.total_spent
),
HighValueCustomers AS (
    SELECT 
        ph.c_custkey, 
        ph.c_name, 
        ph.total_spent 
    FROM 
        PurchaseHistory ph
    WHERE 
        ph.total_spent > 5000
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost) AS total_supply_cost 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey 
),
LineitemSummary AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
    FROM 
        lineitem l 
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2023-12-31' 
    GROUP BY 
        l.l_partkey 
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(hi.c_name, 'Unknown') AS high_value_customer_name,
    si.s_name AS supplier_name,
    ls.total_revenue,
    (si.total_supply_cost / NULLIF(ls.total_revenue, 0)) AS cost_to_revenue_ratio
FROM 
    part p
LEFT JOIN 
    HighValueCustomers hi ON hi.c_custkey = (
        SELECT 
            MAX(c.c_custkey) 
        FROM 
            HighValueCustomers c 
        WHERE 
            c.custkey IN (SELECT c.c_custkey FROM customer)
    )
LEFT JOIN 
    SupplierPartInfo si ON p.p_partkey = si.ps_partkey
LEFT JOIN 
    LineitemSummary ls ON p.p_partkey = ls.l_partkey
WHERE 
    p.p_retailprice > 100 AND 
    (p.p_size IN (10, 20) OR p.p_brand LIKE 'Brand%')
ORDER BY 
    cost_to_revenue_ratio DESC, 
    total_revenue DESC;
