WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    r.region_name,
    rs.s_name AS top_supplier,
    hvc.c_name AS high_value_customer,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
JOIN 
    HighValueCustomers hvc ON o.o_custkey = hvc.c_custkey
JOIN 
    nation n ON rs.nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '2022-01-01' 
    AND l.l_shipdate < '2023-01-01'
GROUP BY 
    r.region_name, rs.s_name, hvc.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    r.region_name, total_sales DESC;
