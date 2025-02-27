WITH RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) as price_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    GROUP BY ps.ps_suppkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment != 'AUTOMOBILE'
    GROUP BY c.c_custkey
    HAVING total_spent > 1000.00
),
FinalResults AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT co.c_custkey) AS customer_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM RankedLineItems l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer co ON o.o_custkey = co.c_custkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE l.l_shipmode IN ('AIR', 'FOB') 
        AND EXISTS (
            SELECT 1 
            FROM TopSuppliers ts 
            WHERE ts.ps_suppkey = s.s_suppkey
        )
    GROUP BY n.n_name
)
SELECT 
    fr.nation_name, 
    fr.customer_count, 
    fr.total_lineitem_value,
    CASE 
        WHEN fr.total_lineitem_value IS NULL THEN 'No Value'
        ELSE 'Value Exists'
    END AS value_status,
    COALESCE(MAX(rl.price_rank), 0) AS max_price_rank
FROM FinalResults fr
LEFT JOIN RankedLineItems rl ON fr.nation_name = (
    SELECT n.n_name 
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        GROUP BY ps.ps_suppkey 
        HAVING SUM(ps.ps_supplycost) > 5000
    )
    LIMIT 1
)
GROUP BY fr.nation_name, fr.customer_count, fr.total_lineitem_value
ORDER BY fr.customer_count DESC, fr.total_lineitem_value DESC
LIMIT 10;
