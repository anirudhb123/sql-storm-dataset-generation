WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
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
        o.o_orderstatus = 'G'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT nc.n_nationkey) AS nation_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(l.l_tax) AS avg_tax,
    STRING_AGG(DISTINCT c.c_name) AS top_customers
FROM 
    region r
JOIN 
    nation nc ON r.r_regionkey = nc.n_regionkey
JOIN 
    supplier s ON nc.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    TopCustomers tc ON tc.c_custkey = l.l_orderkey
WHERE 
    l.l_shipdate >= DATE '2023-01-01'
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC
LIMIT 10;
