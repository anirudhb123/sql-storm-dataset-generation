WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
ActiveCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) as rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000.00
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    s.total_avail_qty,
    s.total_supply_cost,
    c.c_name AS customer_name,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Pending'
    END AS order_status_text,
    COALESCE(s.total_avail_qty / NULLIF(s.total_supply_cost, 0), 0) AS cost_per_avail_qty
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierParts s ON s.total_avail_qty IS NOT NULL
JOIN 
    ActiveCustomers c ON c.rank <= 10 
WHERE 
    r.rank <= 5 
    AND r.o_totalprice > 500.00
ORDER BY 
    r.o_totalprice DESC, 
    r.o_orderdate ASC;
