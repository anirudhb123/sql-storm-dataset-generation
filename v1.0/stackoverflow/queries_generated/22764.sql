WITH UserScoreCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Score,
        PH.CreationDate AS ChangeDate,
        PHT.Name AS ChangeType,
        COALESCE(PH.Comment, 'No comment') AS ChangeComment
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    AND (P.Score IS NULL OR P.Score > 0) 
),
PostRanked AS (
    SELECT 
        FP.*,
        ROW_NUMBER() OVER (PARTITION BY FP.OwnerUserId ORDER BY FP.Score DESC) AS RankPerUser
    FROM FilteredPosts FP
),
TopPosts AS (
    SELECT 
        PR.*,
        US.DisplayName AS OwnerDisplayName,
        US.Reputation AS OwnerReputation,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM PostRanked PR
    LEFT JOIN Users US ON PR.OwnerUserId = US.Id
    LEFT JOIN Votes V ON PR.PostId = V.PostId
    WHERE PR.RankPerUser <= 3
    GROUP BY PR.PostId, US.DisplayName, US.Reputation
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    TP.Score,
    TP.ChangeType,
    TP.ChangeDate,
    TP.ChangeComment,
    TP.OwnerDisplayName,
    TP.OwnerReputation,
    TP.Downvotes,
    CASE 
        WHEN TP.Score IS NULL THEN 'Score not available'
        WHEN TP.Score > 10 THEN 'High Score'
        WHEN TP.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    RANK() OVER (ORDER BY TP.Score DESC) AS GlobalRank
FROM TopPosts TP
WHERE TP.Downvotes > 2 OR TP.OwnerReputation > 1000
ORDER BY TP.Score DESC, TP.ViewCount DESC
LIMIT 50;

This query consists of multiple CTEs (Common Table Expressions) to structure the logic for user scores, filtered posts, ranking within users, and identifying top posts. It employs various SQL features including:

- **CTEs** for better organization of logic.
- **Left Joins** to combine data from related tables while still retaining posts with no history.
- **Window Functions** for ranking users and posts based on scores.
- **COALESCE** to handle potential NULL values.
- **Complex Conditional Logic** implementing case statements for score categorization.

The query ultimately retrieves a list of specific posts that meet certain criteria, including associated metadata, while implementing sophisticated filtering and ranking based on user reputation and downvotes.
