WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
        AND o.o_totalprice IS NOT NULL
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal > 0
        AND (o.o_orderstatus IS NULL OR o.o_orderstatus = 'O')
    GROUP BY 
        c.c_custkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        SUM(co.total_spent) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        CustomerOrders co ON co.c_custkey = c.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ns.n_name,
    ns.unique_customers,
    ns.total_revenue,
    po.ps_partkey,
    po.total_avail_qty,
    po.avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    NationSummary nsm ON nsm.n_nationkey = ns.n_nationkey
JOIN 
    PartSupplier po ON po.ps_partkey = 
    (
        SELECT 
            ps.ps_partkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_supplycost = (SELECT MAX(ps2.ps_supplycost) FROM partsupp ps2)
        FETCH FIRST 1 ROW ONLY
    )
WHERE 
    (ns.total_revenue IS NOT NULL OR nsm.total_revenue IS NULL)
    AND EXISTS (
        SELECT 1 
        FROM RankedOrders ro 
        WHERE ro.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderdate < CURRENT_DATE)
    )
ORDER BY 
    r.r_name, ns.unique_customers DESC;
