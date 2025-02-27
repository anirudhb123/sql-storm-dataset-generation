WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        ps.ps_supplycost,
        DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrderAmounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_amount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FlaggedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        CASE 
            WHEN l.l_returnflag = 'Y' THEN 'Returned'
            ELSE 'Not Returned'
        END AS item_status,
        CONCAT(l.l_shipmode, ' with ', l.l_shipinstruct) AS shipping_info
    FROM 
        lineitem l
)
SELECT 
    R.o_orderkey,
    R.o_orderdate,
    S.s_name,
    S.p_name,
    S.available_quantity,
    S.ps_supplycost,
    C.c_name,
    C.total_order_amount,
    L.item_status,
    L.shipping_info,
    CASE 
        WHEN C.total_order_amount IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_existence
FROM 
    RankedOrders R
LEFT JOIN 
    SupplierPartInfo S ON S.available_quantity > 0
LEFT JOIN 
    CustomerOrderAmounts C ON R.o_orderkey = C.c_custkey
LEFT JOIN 
    FlaggedLineItems L ON R.o_orderkey = L.l_orderkey
WHERE 
    EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = R.o_orderkey
        AND l.l_discount > 0
        HAVING COUNT(*) > 2
    )
ORDER BY 
    R.o_orderdate DESC, R.o_orderkey ASC;
