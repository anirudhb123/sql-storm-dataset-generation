WITH PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.PostTypeId,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS Rank,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate > (NOW() - INTERVAL '1 year')
),
RecentVotes AS (
    SELECT
        V.PostId,
        V.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM
        Votes V
    WHERE
        V.CreationDate >= (NOW() - INTERVAL '1 month')
    GROUP BY
        V.PostId, V.VoteTypeId
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT CR.Name, ', ') AS CloseReasons
    FROM
        PostHistory PH
    JOIN
        CloseReasonTypes CR ON PH.Comment::INT = CR.Id
    WHERE
        PH.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY
        PH.PostId
)
SELECT
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.Reputation,
    RV.VoteCount,
    CP.LastClosedDate,
    CP.CloseReasons,
    PS.Rank,
    PS.ScoreRank,
    CASE
        WHEN PS.AnswerCount > 0 THEN 'Active'
        WHEN CP.LastClosedDate IS NOT NULL AND PS.ScoreRank <= 10 THEN 'Needs Attention'
        ELSE 'Backlog'
    END AS PostStatus,
    CASE
        WHEN PS.PostTypeId = 1 THEN 'Question'
        WHEN PS.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType
FROM
    PostStatistics PS
LEFT JOIN
    RecentVotes RV ON PS.PostId = RV.PostId AND RV.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
LEFT JOIN
    ClosedPosts CP ON PS.PostId = CP.PostId
WHERE
    PS.Rank <= 10 -- Only top 10 posts by ViewCount for each PostType
ORDER BY
    PS.ViewCount DESC, PS.Reputation DESC;

This SQL query features:
1. Common Table Expressions (CTEs) for `PostStatistics`, `RecentVotes`, and `ClosedPosts` to separate various aggregations and complexities.
2. Window functions to determine rankings by views and scores.
3. Conditional logic to classify posts based on their activity and closure status.
4. String aggregation for closed posts' reasons.
5. Complex predicates in the WHERE clauses filtering posts created in the last year only.

This blend of components provides a multifaceted analysis of posts in a performance benchmarking scenario while showcasing sophisticated SQL capabilities.
