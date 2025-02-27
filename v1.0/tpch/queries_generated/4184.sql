WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
        o.o_orderstatus IS NULL OR o.o_orderdate > '2022-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        COALESCE(SUM(l.l_quantity), 0) AS total_sold
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty
)
SELECT 
    c.c_name,
    COALESCE(sc.total_cost, 0) AS supplier_total_cost,
    pi.p_name,
    pi.p_retailprice,
    pi.ps_availqty,
    pi.total_sold,
    COALESCE(co.order_count, 0) AS customer_order_count,
    co.total_spent,
    CASE 
        WHEN pi.total_sold > 100 THEN 'High Sales'
        WHEN pi.total_sold BETWEEN 50 AND 100 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    SupplierCosts sc
FULL OUTER JOIN 
    CustomerOrders co ON sc.s_suppkey = co.c_custkey
FULL OUTER JOIN 
    PartSupplierInfo pi ON pi.ps_availqty > 0
WHERE 
    (sc.total_cost IS NOT NULL OR co.total_spent IS NOT NULL OR pi.total_sold > 0)
ORDER BY 
    supplier_total_cost DESC, total_spent DESC;
