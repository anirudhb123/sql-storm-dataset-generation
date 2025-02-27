WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSupply AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        l.l_returnflag,
        l.l_linestatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate <= '2023-10-31'
    GROUP BY o.o_orderkey, o.o_orderdate, l.l_returnflag, l.l_linestatus
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    sd.nation_name,
    sd.region_name,
    sd.s_acctbal,
    SUM(od.total_order_value) AS total_value,
    ps.total_available_quantity,
    ps.total_supply_cost
FROM part pd
JOIN PartSupply ps ON pd.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN OrderDetails od ON od.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderdate >=  DATEADD(MONTH, -3, CURRENT_DATE)
)
GROUP BY 
    pd.p_partkey, 
    pd.p_name, 
    sd.nation_name, 
    sd.region_name, 
    sd.s_acctbal,
    ps.total_available_quantity,
    ps.total_supply_cost
ORDER BY total_value DESC, sd.s_acctbal DESC
LIMIT 100;
