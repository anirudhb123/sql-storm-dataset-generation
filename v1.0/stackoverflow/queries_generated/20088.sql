WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS RN
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        PT.Name AS PostType,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Votes V ON RP.PostId = V.PostId
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    LEFT JOIN 
        PostTypes PT ON RP.PostTypeId = PT.Id
    GROUP BY 
        RP.PostId, PT.Name, RP.Title, RP.Score, RP.ViewCount
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 10) AS ClosureCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
FinalStats AS (
    SELECT 
        PS.*,
        COALESCE(CP.ClosureCount, 0) AS ClosureCount
    FROM 
        PostStats PS
    LEFT JOIN 
        ClosedPosts CP ON PS.PostId = CP.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.PostType,
    PS.Score,
    PS.ViewCount,
    PS.UpVotes - PS.DownVotes AS NetVotes,
    PS.CommentCount,
    PS.ClosureCount,
    CASE 
        WHEN PS.Score = 0 THEN 'Neutral'
        WHEN PS.Score > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS ScoreCategory
FROM 
    FinalStats PS
WHERE 
    PS.ClosureCount = 0
    AND PS.RN <= 5
    AND PS.ViewCount BETWEEN 100 AND 1000
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount ASC NULLS LAST;

This SQL query incorporates several SQL constructs and features:
1. **Common Table Expressions (CTEs)**: Multiple CTEs are used to organize the logic, including ranking posts, aggregating statistics, and tracking closed posts.
2. **Window Functions**: The `ROW_NUMBER` function is used to rank posts based on their score and creation date.
3. **Aggregates and Conditional Logic**: The query counts votes and comments and applies conditional aggregation to get upvotes and downvotes.
4. **Outer Joins**: Used to get closure counts for posts while still including those that haven’t been closed.
5. **Complex Predicates**: Filters to include only those posts that have a specific view count and were active in the past year.
6. **String Expressions and Calculations**: Categorizes posts based on their score, illustrating a mix of performance measurement and post engagement.
7. **NULL Logic**: Utilizes `COALESCE` to handle potential nulls from outer joins appropriately.
8. **Obscure Semantics**: The use of `NULLS LAST` in the `ORDER BY` clause provides a niche flexibility in sorting.

This query could be used as a benchmark for evaluating performance in handling complex SQL constructs and the calculations they entail.
