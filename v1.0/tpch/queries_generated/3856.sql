WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    t.c_name,
    su.s_name,
    su.nation_name,
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate
FROM 
    TopCustomers t
JOIN 
    RankedOrders r ON r.o_orderkey IN (
        SELECT 
            l.l_orderkey
        FROM 
            lineitem l
        WHERE 
            l.l_quantity > 10
    )
LEFT JOIN 
    SupplierDetails su ON su.total_available > 100
WHERE 
    r.order_rank <= 5
ORDER BY 
    t.total_spent DESC, r.o_totalprice ASC;
