WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    n.n_name AS nation, 
    SUM(CASE WHEN r.rank <= 5 THEN r.total_cost ELSE 0 END) AS top_supplier_cost,
    COUNT(h.c_custkey) AS high_value_customer_count
FROM 
    RankedSuppliers r
JOIN 
    nation n ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 200))
LEFT JOIN 
    HighValueCustomers h ON h.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderdate >= '2022-01-01')
GROUP BY 
    n.n_name;
