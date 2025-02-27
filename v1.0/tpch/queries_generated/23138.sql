WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank_suppliers
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice, p.p_size
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
), 
CustomerOrders AS (
    SELECT  
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        (li.l_extendedprice * (1 - li.l_discount)) AS discounted_price,
        DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY li.l_linenumber) as price_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_shipdate IS NOT NULL AND li.l_discount > 0
), 
FinalResults AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        ps.p_name,
        ps.p_retailprice,
        os.discounted_price,
        os.price_rank,
        CASE 
            WHEN rank_suppliers <= 5 THEN 'Top Supplier'
            ELSE 'Other Supplier'
        END as supplier_rank
    FROM CustomerOrders co
    JOIN FilteredParts ps ON ps.p_retailprice > 100
    LEFT JOIN RankedSuppliers rs ON co.c_custkey = rs.s_nationkey
    JOIN OrderDetails os ON os.l_partkey = ps.p_partkey AND os.price_rank = 1
    WHERE co.c_acctbal IS NOT NULL
    ORDER BY co.total_spent DESC, ps.p_retailprice
)
SELECT * FROM FinalResults
WHERE supplier_rank = 'Top Supplier' 
  OR discounted_price IS NULL 
  OR (SELECT COUNT(*) FROM lineitem WHERE l_discount IS NOT NULL) > 1000;
