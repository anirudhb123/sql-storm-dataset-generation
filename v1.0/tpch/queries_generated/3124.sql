WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.n_name AS nation_name,
    SUM(od.total_price) AS total_order_value,
    AVG(s.total_supplier_cost) AS average_supplier_cost,
    COUNT(DISTINCT rc.c_custkey) AS active_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedCustomers rc ON n.n_nationkey = rc.c_nationkey AND rc.rank <= 10
LEFT JOIN 
    OrderDetails od ON rc.c_custkey = od.o_orderkey
LEFT JOIN 
    SupplierCost s ON od.o_orderkey = s.ps_partkey
WHERE 
    r.r_name LIKE '%East%'
GROUP BY 
    r.n_name
HAVING 
    COUNT(DISTINCT rc.c_custkey) > 5
ORDER BY 
    total_order_value DESC;
