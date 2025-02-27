WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= (SELECT MIN(o_orderdate) FROM orders) 
        AND o.o_totalprice IS NOT NULL
), 
SupplierStatus AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(CASE WHEN ps.ps_availqty = 0 THEN 1 END) AS out_of_stock_count
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
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    COALESCE(ss.total_supply_value, 0) AS supplier_value,
    h.c_name,
    h.total_spent,
    CASE 
        WHEN ss.out_of_stock_count > 0 THEN 'Some Items Out of Stock' 
        ELSE 'All Items Available' 
    END AS stock_status
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierStatus ss ON ss.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierStatus)
LEFT JOIN 
    HighValueCustomers h ON h.total_spent = (SELECT MAX(total_spent) FROM HighValueCustomers WHERE c_custkey < h.c_custkey)
WHERE 
    r.order_rank = 1
ORDER BY 
    r.o_totalprice DESC, h.c_name ASC;
