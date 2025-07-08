
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
        AND o.o_orderdate < DATE '1996-01-01'
),
LowBalanceCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal < (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OutOfStockParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(sa.total_avail_qty, 0) AS avail_qty
    FROM 
        part p
    LEFT JOIN 
        SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
    WHERE 
        COALESCE(sa.total_avail_qty, 0) = 0
),
OrderItemCounts AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE 
            WHEN o.o_orderstatus = 'F' OR o.o_orderstatus = 'P' THEN o.o_totalprice 
            ELSE 0 
        END) AS fulfilled_total,
    AVG(COALESCE(c.c_acctbal, 0)) AS average_low_balance,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS out_of_stock_parts
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN 
    LowBalanceCustomers c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    OutOfStockParts p ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
LEFT JOIN 
    OrderItemCounts ic ON o.o_orderkey = ic.l_orderkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
    AND AVG(COALESCE(c.c_acctbal, 0)) < 500
ORDER BY 
    total_orders DESC;
