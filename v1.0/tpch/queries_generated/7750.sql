WITH RegionNation AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
),
SupplierPart AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
LineItemDetails AS (
    SELECT li.l_orderkey, li.l_partkey, li.l_discount, li.l_quantity, li.l_extendedprice
    FROM lineitem li
    JOIN CustomerOrders co ON li.l_orderkey = co.o_orderkey
    WHERE li.l_shipdate >= '2023-01-01' AND li.l_shipdate <= '2023-12-31'
),
FinalResult AS (
    SELECT rn.r_name, np.n_name, sp.s_name, SUM(lid.l_extendedprice * (1 - lid.l_discount)) AS revenue
    FROM LineItemDetails lid
    JOIN SupplierPart sp ON lid.l_partkey = sp.ps_partkey
    JOIN RegionNation rn ON sp.s_suppkey = sp.ps_suppkey
    GROUP BY rn.r_name, np.n_name, sp.s_name
)
SELECT r_name, n_name, s_name, revenue
FROM FinalResult
ORDER BY revenue DESC
LIMIT 10;
