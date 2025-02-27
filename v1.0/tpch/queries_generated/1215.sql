WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT 
        l.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM 
        lineitem l
    GROUP BY 
        l.o_orderkey
)
SELECT 
    O.o_orderkey,
    O.o_orderdate,
    O.o_totalprice,
    LD.line_count,
    LD.total_price_after_discount,
    S.total_supply_cost,
    CASE 
        WHEN O.o_totalprice IS NULL THEN 'Total Price Missing'
        ELSE CAST(O.o_totalprice AS VARCHAR) 
    END AS price_info,
    R.price_rank,
    (SELECT MAX(c.c_acctbal) FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')) AS max_us_cust_balance
FROM 
    RankedOrders R
LEFT JOIN 
    LineItemStats LD ON R.o_orderkey = LD.o_orderkey
LEFT JOIN 
    SupplierDetails S ON S.total_supply_cost > 10000
WHERE 
    R.price_rank <= 5
ORDER BY 
    R.o_orderdate DESC, 
    O.o_totalprice ASC;
