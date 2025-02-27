WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
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
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2022-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        r.r_name AS region_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        p.p_retailprice > 100.00
)
SELECT 
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    tc.c_name AS customer_name,
    p.p_name AS part_name,
    p.supplier_name,
    p.ps_availqty,
    p.ps_supplycost,
    p.region_name
FROM 
    RankedOrders ro
JOIN 
    TopCustomers tc ON ro.c_name = tc.c_name
JOIN 
    PartSupplierDetails p ON ro.o_orderkey IN 
    (SELECT l.l_orderkey 
     FROM lineitem l 
     WHERE l.l_partkey = p.p_partkey)
WHERE 
    ro.rn <= 5
ORDER BY 
    ro.o_totalprice DESC;
