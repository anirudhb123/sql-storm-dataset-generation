WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT 
                AVG(c2.c_acctbal) 
            FROM 
                customer c2
        )
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_orderstatus,
    s.s_name AS supplier_name,
    r.region_name,
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    COALESCE(rh.total_revenue, 0) AS total_revenue
FROM 
    RankedOrders rh
FULL OUTER JOIN 
    SupplierDetails s ON rh.o_orderkey = s.s_suppkey
JOIN 
    HighValueCustomers c ON c.c_custkey = (SELECT o_custkey FROM orders WHERE o_orderkey = rh.o_orderkey)
WHERE 
    rh.order_rank <= 10
ORDER BY 
    total_revenue DESC, customer_balance DESC;
