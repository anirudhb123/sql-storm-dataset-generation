WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        TO_CHAR(o.o_orderdate, 'YYYY-MM-DD') AS formatted_orderdate
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') AND o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2 
        WHERE o2.o_orderstatus = o.o_orderstatus
    )
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) OVER (PARTITION BY ps.ps_partkey) AS total_availqty,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    WHERE ps.ps_supplycost IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    R.o_orderkey,
    R.formatted_orderdate,
    COALESCE(SP.total_availqty, 0) AS total_available_quantity,
    COALESCE(CO.order_count, 0) AS order_count,
    SP.unique_suppliers
FROM RankedOrders R
LEFT JOIN SupplierParts SP ON R.o_orderkey = SP.ps_partkey
LEFT JOIN CustomerOrders CO ON R.o_orderkey = CO.c_custkey
WHERE R.price_rank <= 5 
    AND (SP.total_availqty IS NULL OR SP.total_availqty > 100)
ORDER BY R.o_orderkey, CO.total_spent DESC;
