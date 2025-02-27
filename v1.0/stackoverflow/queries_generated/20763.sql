WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), 0) AS AcceptedAnswer,
        PH.UserDisplayName AS LastEditor,
        PH.CreationDate AS LastEditDate,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 10)
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, PH.UserDisplayName, PH.CreationDate
),
TopPostInteractions AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.ViewCount,
        PS.AnswerCount,
        PS.AcceptedAnswer,
        PS.LastEditor,
        PS.LastEditDate,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        RANK() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.ViewCount DESC) AS RankByViews
    FROM PostStats PS
    JOIN Users U ON PS.OwnerUserId = U.Id
    WHERE U.Reputation > 1000 AND PS.UserPostRank <= 3
),
FilteredPosts AS (
    SELECT 
        TP.*,
        (TP.UpVotes - TP.DownVotes) AS Score,
        CASE 
            WHEN TP.AcceptedAnswer IS NOT NULL THEN 'Accepted Answer Exists' 
            ELSE 'No Accepted Answer' 
        END AS AnswerStatus
    FROM TopPostInteractions TP
    WHERE TP.RankByViews <= 5
        AND TP.Score >= 0
        AND (TP.CommentCount IS NULL OR TP.CommentCount < 10)
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.ViewCount,
    FP.AnswerCount,
    FP.AcceptedAnswer,
    FP.LastEditor,
    FP.LastEditDate,
    FP.UpVotes,
    FP.DownVotes,
    FP.CommentCount,
    FP.Score,
    FP.AnswerStatus
FROM FilteredPosts FP
LEFT JOIN PostHistory PH ON FP.PostId = PH.PostId
WHERE PH.PostHistoryTypeId IN (10, 11, 12) AND (PH.CreationDate IS NOT NULL OR PH.Comment IS NULL)
ORDER BY FP.Score DESC, FP.ViewCount DESC;

-- In this query:
-- 1. A CTE `PostStats` is created to gather initial stats including votes and comments for each post.
-- 2. The second CTE `TopPostInteractions` ranks posts based on views per user and filters by user reputation.
-- 3. The `FilteredPosts` CTE applies additional filters based on score and comments and evaluates acceptance of answers.
-- 4. The final selection retrieves relevant data from the filtered posts, including post history and certain predicates.
