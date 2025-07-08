
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT 
        rc.c_custkey, 
        rc.c_name, 
        rc.total_spent 
    FROM 
        RankedCustomers rc 
    WHERE 
        rc.rank <= 10
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        s.s_name AS supplier_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
SalesHistory AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        o.o_orderdate,
        c.c_custkey
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    h.c_name AS customer_name,
    COUNT(DISTINCT sh.l_orderkey) AS number_of_orders,
    SUM(sh.l_quantity) AS total_quantity_ordered,
    SUM(sh.l_extendedprice) AS total_revenue,
    LISTAGG(DISTINCT CONCAT(pd.p_name, ' (', pd.supplier_name, ')'), ', ') AS products_supplied
FROM 
    HighSpenders h
JOIN 
    SalesHistory sh ON h.c_custkey = sh.c_custkey
JOIN 
    PartSupplierDetails pd ON sh.l_partkey = pd.p_partkey
GROUP BY 
    h.c_custkey, h.c_name
ORDER BY 
    total_revenue DESC;
