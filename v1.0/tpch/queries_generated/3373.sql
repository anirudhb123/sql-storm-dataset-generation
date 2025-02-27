WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        SUM(o.o_totalprice) > 100000
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey 
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
)
SELECT 
    r.r_name,
    cs.c_name,
    cs.total_spent,
    TO_CHAR(r.o_orderdate, 'YYYY-MM-DD') AS order_date,
    COUNT(DISTINCT lo.l_orderkey) AS line_item_count,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS revenue
FROM 
    RankedOrders r 
INNER JOIN 
    CustomerSummary cs ON r.o_orderkey = cs.c_custkey 
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey 
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.ps_suppkey 
WHERE 
    r.order_rank <= 10 
    AND l.l_returnflag = 'N'
    AND l.l_shipdate IS NOT NULL
GROUP BY 
    r.r_name, cs.c_name, r.o_orderdate
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    total_spent DESC, r.o_orderdate DESC;
