WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
), 
TopCustomers AS (
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
        SUM(o.o_totalprice) > 5000
),
PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 3
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.supplier_count,
    COALESCE(SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END), 0) AS total_returns,
    COALESCE(MIN(CASE WHEN li.l_linestatus = 'O' THEN li.l_shipdate END), 'No Shipping') AS last_open_shipment,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    PartSupplierCount ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = li.l_orderkey
LEFT JOIN 
    TopCustomers c ON c.c_custkey = ro.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, ps.supplier_count
HAVING 
    total_returns > 100 OR supplier_count IS NULL
ORDER BY 
    p.p_partkey;
