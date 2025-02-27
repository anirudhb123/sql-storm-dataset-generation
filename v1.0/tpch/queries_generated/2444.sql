WITH SupplyCosts AS (
    SELECT 
        ps.partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.partkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), OrderLineData AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_tax DESC) AS tax_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
), CombinedData AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        sl.total_supply_cost,
        ol.l_quantity,
        ol.l_extendedprice
    FROM CustomerOrders co
    LEFT JOIN SupplyCosts sl ON sl.partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%' LIMIT 1)
    LEFT JOIN OrderLineData ol ON ol.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
)

SELECT 
    cd.c_name, 
    cd.total_supply_cost,
    COALESCE(SUM(cd.l_extendedprice), 0) AS total_extended_price,
    COUNT(cd.l_quantity) AS total_line_items,
    AVG(cd.l_quantity) AS avg_quantity_per_item,
    SUM(CASE WHEN cd.l_extendedprice > 100 THEN 1 ELSE 0 END) AS high_value_items
FROM CombinedData cd
GROUP BY cd.c_name, cd.total_supply_cost
HAVING total_extended_price > 0
ORDER BY total_extended_price DESC;
