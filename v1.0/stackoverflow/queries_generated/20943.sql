WITH UserReputationRanks AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        COALESCE(P.FavoriteCount, 0) AS FavoriteCount,
        P.CreationDate,
        PT.Name AS PostType,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened
    GROUP BY 
        PH.PostId
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.FavoriteCount,
        CPH.FirstClosedDate,
        CPH.CloseCount,
        UP.ReputationRank
    FROM 
        PostStatistics PS
    LEFT JOIN 
        ClosedPostHistory CPH ON PS.PostId = CPH.PostId
    JOIN 
        Users U ON PS.OwnerDisplayName = U.DisplayName
    JOIN 
        UserReputationRanks UP ON U.Id = UP.UserId
    WHERE 
        PS.Score > (SELECT AVG(Score) FROM Posts)  -- Only high-scoring posts
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    RP.CommentCount,
    RP.FavoriteCount,
    RP.FirstClosedDate,
    RP.CloseCount,
    RP.ReputationRank,
    CASE 
        WHEN RP.FirstClosedDate IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS IsClosed,
    CONCAT(UP.DisplayName, ' (Rank ', RP.ReputationRank, ')') AS OwnerDetails
FROM 
    RankedPosts RP
LEFT JOIN 
    Users UP ON RP.OwnerDisplayName = UP.DisplayName  -- Owner details
WHERE 
    RP.CloseCount IS NULL OR RP.CloseCount = 0  -- To filter out closed posts
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC;
This SQL query includes several advanced techniques:
- Common Table Expressions (CTEs) for structuring the query into reusable segments.
- A ranking function to rank users by reputation.
- Outer joins to combine various tables while preserving rows.
- A correlated subquery to calculate high-scoring posts against the average score.
- Use of COALESCE to handle NULL values effectively.
- Complicated predicates to filter posts based on multiple criteria, including checks for post closure and user reputation.
- String concatenation for enriched output detailing owner information.

The query selects high-scoring posts, incorporates statistics about closure history, and ranks the authors by reputation, all while filtering out closed posts.
