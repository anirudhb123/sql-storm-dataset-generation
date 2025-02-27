WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
), 
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_amount,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
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
)

SELECT 
    sr.s_suppkey,
    sr.s_name,
    cr.c_custkey,
    cr.c_name,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(cr.total_spent, 0) AS total_spent,
    lr.total_line_amount,
    lr.line_rank,
    nr.region_name
FROM 
    SupplierPerformance sr
FULL OUTER JOIN 
    CustomerOrderStats cr ON sr.s_suppkey = cr.c_custkey
FULL OUTER JOIN 
    LineItemStats lr ON sr.s_suppkey = lr.l_orderkey
INNER JOIN 
    NationRegion nr ON COALESCE(sr.s_suppkey, cr.c_custkey) = nr.n_nationkey
WHERE 
    (sr.total_supply_cost > 1000 OR cr.total_spent > 500)
    AND (lr.line_rank = 1 OR lr.line_rank IS NULL)
ORDER BY 
    total_supply_cost DESC, total_spent DESC;
