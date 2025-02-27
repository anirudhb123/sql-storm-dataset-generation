WITH SupplierSummary AS (
    SELECT 
        S.s_suppkey,
        S.s_name,
        S.s_acctbal,
        SUM(PS.ps_supplycost * PS.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT PS.ps_partkey) AS part_count
    FROM supplier S
    JOIN partsupp PS ON S.s_suppkey = PS.ps_suppkey
    GROUP BY S.s_suppkey, S.s_name, S.s_acctbal
),
OrderDetails AS (
    SELECT 
        O.o_orderkey,
        O.o_orderdate,
        C.c_name,
        C.c_nationkey,
        L.l_extendedprice * (1 - L.l_discount) AS net_price,
        ROW_NUMBER() OVER (PARTITION BY O.o_orderkey ORDER BY L.l_linenumber) AS line_number
    FROM orders O
    JOIN customer C ON O.o_custkey = C.c_custkey
    JOIN lineitem L ON O.o_orderkey = L.l_orderkey
    WHERE O.o_orderdate >= '1997-01-01' AND O.o_orderdate < '1997-12-31'
),
NationRevenue AS (
    SELECT 
        N.n_name,
        SUM(D.net_price) AS total_revenue
    FROM OrderDetails D
    JOIN nation N ON D.c_nationkey = N.n_nationkey
    GROUP BY N.n_name
)
SELECT 
    R.r_name,
    COALESCE(NR.total_revenue, 0) AS nation_revenue,
    S.total_supply_cost,
    S.part_count
FROM region R
LEFT JOIN NationRevenue NR ON R.r_regionkey = (SELECT n_regionkey FROM nation WHERE n_name = NR.n_name)
LEFT JOIN SupplierSummary S ON S.total_supply_cost > 100000
WHERE R.r_name LIKE 'A%'
ORDER BY nation_revenue DESC, part_count DESC;