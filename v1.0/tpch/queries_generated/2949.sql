WITH SupplierDetails AS (
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
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (
            SELECT AVG(SUM(o1.o_totalprice))
            FROM orders o1
            WHERE o1.o_orderstatus = 'O'
            GROUP BY o1.o_custkey
        )
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' 
        AND l.l_shipdate <= DATE '2023-12-31' 
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supply_cost,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierDetails sd
)

SELECT 
    p.p_name,
    p.total_sales,
    r.s_name AS top_supplier,
    r.total_supply_cost,
    c.c_name AS high_value_customer,
    c.total_spent
FROM 
    PartSales p
LEFT JOIN 
    RankedSuppliers r ON p.sales_rank = r.supplier_rank
LEFT JOIN 
    HighValueCustomers c ON c.total_spent > 1000
WHERE 
    p.total_sales IS NOT NULL
ORDER BY 
    p.total_sales DESC, r.total_supply_cost DESC
FETCH FIRST 10 ROWS ONLY;
