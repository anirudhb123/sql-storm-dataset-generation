WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
ImportantParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 500000
)
SELECT 
    rc.c_name,
    rc.total_spent,
    tr.r_name,
    ip.p_name,
    ip.total_revenue
FROM 
    RankedCustomers rc
JOIN 
    CustomerRegion cr ON rc.c_custkey = cr.custkey
JOIN 
    TopRegions tr ON cr.regionkey = tr.n_regionkey
JOIN 
    ImportantParts ip ON rc.total_spent >= 50000
ORDER BY 
    rc.total_spent DESC, ip.total_revenue DESC;
