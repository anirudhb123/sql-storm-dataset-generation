WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerTotal AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COALESCE(SUM(cd.total_spent), 0) AS total_customer_spending,
    COALESCE(SUM(sd.total_available), 0) AS total_available_parts,
    COALESCE(SUM(sd.total_supplycost), 0) AS total_supply_cost,
    AVG(al.item_count) AS avg_items_per_order
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerTotal cd ON c.c_custkey = cd.c_custkey
LEFT JOIN 
    SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
LEFT JOIN 
    AggregatedLineItems al ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = al.l_orderkey)
GROUP BY 
    n.n_name
ORDER BY 
    n.n_name;