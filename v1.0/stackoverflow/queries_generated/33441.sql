WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        0 AS Level
    FROM Posts P
    WHERE P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        RP.Level + 1
    FROM Posts P
    INNER JOIN RecursivePostHierarchy RP ON P.ParentId = RP.PostId
),
UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(PH.AnswerCount, 0) AS AnswerCount,
        COALESCE(PH.CommentCount, 0) AS CommentCount,
        COALESCE(PH.Score, 0) AS Score,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS AnswerCount,
            SUM(CommentCount) AS CommentCount,
            SUM(Score) AS Score
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY PostId
    ) PH ON P.Id = PH.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    GROUP BY P.Id
),
FinalSummary AS (
    SELECT 
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Score,
        COALESCE(U.UserId, -1) AS UserId,
        COALESCE(U.DisplayName, 'Anonymous') AS UserDisplayName,
        U.TotalVotes,
        U.UpVotes,
        U.DownVotes,
        CASE 
            WHEN P.Score > 0 THEN 'Positive'
            WHEN P.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM PostMetrics P
    LEFT JOIN UserVoteStats U ON P.PostId = U.UserId
)
SELECT 
    F.*,
    COUNT(RPH.PostId) AS RelatedPostCount
FROM FinalSummary F
LEFT JOIN RecursivePostHierarchy RPH ON F.PostId = RPH.PostId
GROUP BY 
    F.UserId, F.UserDisplayName, F.Title, F.ViewCount, 
    F.AnswerCount, F.CommentCount, F.Score, 
    U.TotalVotes, U.UpVotes, U.DownVotes
ORDER BY F.Score DESC, F.ViewCount DESC;
