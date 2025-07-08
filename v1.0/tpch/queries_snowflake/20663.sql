WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        CTE_CustomerInfo.c_mktsegment
    FROM orders o
    JOIN customer CTE_CustomerInfo ON o.o_custkey = CTE_CustomerInfo.c_custkey
    WHERE CTE_CustomerInfo.c_acctbal IS NOT NULL
      AND CTE_CustomerInfo.c_mktsegment IN ('BUILDING','AUTOMOBILE','FURNITURE')
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
), FinalResults AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.o_totalprice,
        sr.region_name,
        sp.total_available,
        ROUND(sp.total_available * 0.1, 2) AS additional_quantity,
        CASE 
            WHEN sr.supplier_count IS NULL THEN 'No Suppliers'
            ELSE CAST(sr.supplier_count AS VARCHAR(10))
        END AS supplier_count_str
    FROM RankedOrders ro
    LEFT JOIN SupplierParts sp ON sp.ps_partkey = (SELECT ps.ps_partkey
                                                   FROM partsupp ps
                                                   JOIN lineitem li ON ps.ps_partkey = li.l_partkey
                                                   WHERE li.l_orderkey = ro.o_orderkey
                                                   LIMIT 1)
    LEFT JOIN NationRegion sr ON sr.n_nationkey = (SELECT c.c_nationkey
                                                   FROM customer c
                                                   WHERE c.c_custkey = (SELECT o.o_custkey
                                                                        FROM orders o
                                                                        WHERE o.o_orderkey = ro.o_orderkey
                                                                        LIMIT 1))
    WHERE ro.order_rank <= 5
)

SELECT 
    f.o_orderkey,
    f.o_orderstatus,
    f.o_totalprice,
    f.region_name,
    f.total_available,
    f.additional_quantity,
    f.supplier_count_str
FROM FinalResults f
WHERE f.o_totalprice IS NOT NULL
ORDER BY f.o_orderstatus, f.o_totalprice DESC
LIMIT 100;

