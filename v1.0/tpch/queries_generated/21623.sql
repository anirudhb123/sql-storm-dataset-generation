WITH RecursivePriceSummary AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_price,
        COUNT(DISTINCT l_partkey) AS total_parts,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS price_rank
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COALESCE(r.r_name, 'Unknown Region') AS region_name,
        PS.total_price,
        PS.total_parts
    FROM 
        orders AS o
    LEFT JOIN RecursivePriceSummary AS PS ON o.o_orderkey = PS.l_orderkey
    LEFT JOIN customer AS c ON o.o_custkey = c.c_custkey
    LEFT JOIN nation AS n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region AS r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
        AND PS.price_rank = 1
    ORDER BY 
        o.o_orderdate DESC
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier AS s
    JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 10000.00
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalBenchmark AS (
    SELECT 
        H.o_orderkey,
        H.o_orderdate,
        H.total_price,
        H.region_name,
        S.s_name,
        S.total_supply_cost,
        CASE 
            WHEN S.total_supply_cost IS NULL THEN 'No Suppliers' 
            ELSE 'Suppliers Available' 
        END AS supplier_status
    FROM 
        HighValueOrders AS H
    FULL OUTER JOIN SupplierDetails AS S ON H.total_parts = (SELECT COUNT(*) FROM lineitem WHERE l_orderkey = H.o_orderkey)
)

SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.total_price,
    COALESCE(f.region_name, 'Not Available') AS final_region_name,
    f.s_name,
    f.total_supply_cost,
    f.supplier_status,
    CASE 
        WHEN f.total_price > 1000 THEN 'High Value'
        WHEN f.total_price IS NULL THEN 'Price Unknown'
        ELSE 'Standard Value'
    END AS order_type,
    CONCAT('Order ', f.o_orderkey, ' in ', COALESCE(f.region_name, 'Unknown Region'), ' with status: ', f.supplier_status) AS order_description
FROM 
    FinalBenchmark AS f
WHERE 
    f.total_price IS NOT NULL OR f.supplier_status = 'No Suppliers'
ORDER BY 
    f.o_orderdate;
