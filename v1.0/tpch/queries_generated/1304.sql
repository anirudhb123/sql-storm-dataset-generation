WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > '2022-01-01'
), SuppliersData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        customerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(SUM(c.total_spent), 0) AS customer_total_spent,
    AVG(s.total_supplycost) AS avg_supply_cost
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueCustomers c ON s.s_suppkey = c.c_custkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' AND
    l.l_returnflag = 'N'
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
