WITH SupplierPricing AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
RegionSupplier AS (
    SELECT 
        r.r_name,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts_provided
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_name
)
SELECT 
    co.c_name,
    sp.s_name,
    rp.r_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(sp.total_cost, 0) AS supplier_cost,
    l.total_lines,
    l.total_value,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN l.total_value > co.total_spent THEN 'Under-spent'
        ELSE 'Valid Spend'
    END AS spend_status
FROM 
    CustomerOrders co
LEFT JOIN 
    SupplierPricing sp ON sp.s_suppkey = (SELECT ps.ps_suppkey
                                            FROM partsupp ps
                                            JOIN lineitem l ON ps.ps_partkey = l.l_partkey
                                            WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
                                            LIMIT 1)
LEFT JOIN 
    LineItemSummary l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
LEFT JOIN 
    RegionSupplier rp ON rp.s_name = sp.s_name
ORDER BY 
    co.total_spent DESC, sp.total_cost DESC;
