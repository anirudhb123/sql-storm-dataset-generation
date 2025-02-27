WITH SupplierCostRanked AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        partsupp ps
),
CustomerOrders AS (
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
        o.o_orderstatus = 'F' 
        OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
    AVG(COALESCE(SUP.total_supply_cost, 0)) AS avg_supplier_cost,
    COALESCE(CU.order_count, 0) AS customer_order_count
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierCostRanked SUP ON p.p_partkey = SUP.ps_partkey AND SUP.rank = 1
LEFT JOIN 
    CustomerOrders CU ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = CU.c_custkey)
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
