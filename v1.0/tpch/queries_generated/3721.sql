WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    si.s_suppkey, 
    si.s_name, 
    si.nation_name, 
    co.total_orders, 
    co.total_spent, 
    od.total_lineitem_value
FROM 
    SupplierInfo si
LEFT JOIN 
    CustomerOrders co ON si.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX' LIMIT 1))
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey LIMIT 1)
WHERE 
    si.rn <= 3
ORDER BY 
    si.nation_name, 
    total_spent DESC;
