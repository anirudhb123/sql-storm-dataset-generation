
WITH RegionalSupplier AS (
    SELECT 
        R.r_name AS region_name,
        S.s_name AS supplier_name,
        SUM(PS.ps_supplycost * PS.ps_availqty) AS total_supply_value
    FROM 
        region R
    JOIN 
        nation N ON R.r_regionkey = N.n_regionkey
    JOIN 
        supplier S ON N.n_nationkey = S.s_nationkey
    JOIN 
        partsupp PS ON S.s_suppkey = PS.ps_suppkey
    GROUP BY 
        R.r_name, S.s_name
),
TopSuppliers AS (
    SELECT 
        region_name,
        supplier_name,
        total_supply_value,
        RANK() OVER (PARTITION BY region_name ORDER BY total_supply_value DESC) AS supplier_rank
    FROM 
        RegionalSupplier
),
OrderSummary AS (
    SELECT 
        C.c_custkey,
        O.o_orderkey,
        O.o_totalprice,
        C.c_acctbal,
        COUNT(L.l_orderkey) AS total_items,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_order_amount
    FROM 
        customer C
    JOIN 
        orders O ON C.c_custkey = O.o_custkey
    LEFT JOIN 
        lineitem L ON O.o_orderkey = L.l_orderkey
    WHERE 
        C.c_acctbal > 100 AND 
        O.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        C.c_custkey, O.o_orderkey, O.o_totalprice, C.c_acctbal
),
FinalReport AS (
    SELECT 
        T.region_name,
        T.supplier_name,
        S.c_custkey,
        S.o_orderkey,
        S.total_order_amount,
        CASE 
            WHEN S.total_order_amount IS NULL THEN 'No orders'
            ELSE 'Has orders'
        END AS order_status
    FROM 
        TopSuppliers T
    LEFT JOIN 
        OrderSummary S ON T.supplier_name = (
            SELECT S2.s_name 
            FROM supplier S2 
            WHERE S2.s_suppkey = (
                SELECT MIN(PS2.ps_suppkey) 
                FROM partsupp PS2 
                WHERE PS2.ps_partkey IN (
                    SELECT PS.ps_partkey 
                    FROM partsupp PS 
                    WHERE PS.ps_supplycost > 100
                )
            )
        )
    WHERE 
        T.supplier_rank <= 5
)
SELECT 
    region_name,
    supplier_name,
    c_custkey,
    o_orderkey,
    total_order_amount,
    order_status
FROM 
    FinalReport
WHERE 
    order_status = 'Has orders' OR (order_status = 'No orders' AND total_order_amount IS NULL)
ORDER BY 
    region_name, supplier_name;
