WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(o.o_totalprice) > 1000000
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rn.o_orderkey,
    rn.o_orderdate,
    tn.n_name AS nation_name,
    sd.s_name AS supplier_name,
    rn.o_totalprice,
    sd.total_available_qty,
    sd.total_supply_cost
FROM 
    RankedOrders rn
JOIN 
    TopNations tn ON rn.o_orderkey IN (
        SELECT o_orderkey
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        WHERE c.c_nationkey = tn.n_nationkey
    )
JOIN 
    lineitem l ON rn.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    rn.order_rank <= 5
ORDER BY 
    tn.total_sales DESC, rn.o_totalprice DESC;