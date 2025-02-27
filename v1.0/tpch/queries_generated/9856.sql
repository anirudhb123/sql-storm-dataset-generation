WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 5
),
PartSupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    TO_VARCHAR(SUM(to.o_totalprice), '999,999,999.99') AS total_orders_value,
    TO_VARCHAR(s.total_supplier_cost, '999,999,999.99') AS total_supplier_cost
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    TopOrders to ON l.l_orderkey = to.o_orderkey
JOIN 
    PartSupplierCost s ON p.p_partkey = s.ps_partkey
GROUP BY 
    p.p_name, p.p_brand, p.p_retailprice, s.total_supplier_cost
ORDER BY 
    total_orders_value DESC, total_supplier_cost DESC
LIMIT 10;
