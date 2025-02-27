WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_availqty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    HAVING 
        SUM(ps.ps_availqty) > 100 AND 
        COUNT(DISTINCT ps.ps_suppkey) < 5
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderDetails AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_extendedprice AS total_line_price,
        li.l_discount,
        li.l_tax,
        CASE 
            WHEN li.l_returnflag = 'Y' THEN 'Returned' 
            ELSE 'Not Returned' 
        END AS return_status
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= '2023-01-01' AND 
        li.l_shipdate <= GETDATE()
)
SELECT 
    r.o_orderkey,
    COUNT(DISTINCT od.l_orderkey) AS orders_count,
    SUM(od.total_line_price) AS total_ship_value,
    SUM(od.l_discount) AS total_discount,
    SUM(od.l_tax) AS total_tax,
    COALESCE(fp.total_availqty, 0) AS total_available_parts,
    CASE
        WHEN hvc.c_custkey IS NOT NULL THEN 'High Value Customer'
        ELSE 'Standard Customer'
    END AS customer_type
FROM 
    RankedOrders r
LEFT JOIN 
    OrderDetails od ON r.o_orderkey = od.l_orderkey
LEFT JOIN 
    FilteredParts fp ON od.l_partkey = fp.p_partkey
LEFT JOIN 
    HighValueCustomers hvc ON r.o_custkey = hvc.c_custkey
WHERE 
    r.order_rank <= 10 AND 
    r.o_orderstatus IN ('F', 'P') 
GROUP BY 
    r.o_orderkey, hvc.c_custkey
HAVING 
    SUM(od.total_line_price) > 1000
ORDER BY 
    r.o_orderdate DESC, total_ship_value DESC;
