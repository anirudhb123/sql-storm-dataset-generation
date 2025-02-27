WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_totalprice > 1000
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    s.s_name AS supplier_name,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    p.p_name,
    p.total_quantity_sold,
    osc.total_spent AS customer_spending,
    COUNT(DISTINCT ro.o_orderkey) AS order_count
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    PartDetails p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    CustomerOrderSummary osc ON osc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey LIMIT 1)
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = osc.c_custkey ORDER BY o.o_orderdate LIMIT 1)
WHERE 
    ps.avg_supply_cost IS NOT NULL
GROUP BY 
    r.r_name, ns.n_name, s.s_name, ps.total_avail_qty, ps.avg_supply_cost, p.p_name, p.total_quantity_sold, osc.total_spent
HAVING 
    SUM(ps.total_avail_qty) > 100
ORDER BY 
    region, nation, supplier_name;