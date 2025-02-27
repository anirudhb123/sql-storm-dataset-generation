
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 100
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-03-31'
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    R.o_orderkey,
    R.o_orderdate,
    COALESCE(S.total_supplycost, 0) AS supplier_cost,
    COALESCE(H.net_price, 0) AS line_item_value,
    CASE 
        WHEN H.net_price IS NULL THEN 'NO LINE ITEMS'
        WHEN S.total_supplycost IS NULL THEN 'NO SUPPLIERS'
        ELSE 'VALUE EXISTS'
    END AS status
FROM 
    RankedOrders R
LEFT JOIN 
    HighValueLineItems H ON R.o_orderkey = H.l_orderkey
LEFT JOIN 
    SupplierInfo S ON S.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey = R.o_orderkey
    )
WHERE 
    R.order_rank <= 5
ORDER BY 
    R.o_orderdate DESC, 
    H.net_price DESC NULLS LAST;
