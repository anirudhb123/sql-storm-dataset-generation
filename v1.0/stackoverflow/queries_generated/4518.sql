WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalBadges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        U.DisplayName AS AuthorDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    INNER JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.Score > 0 AND P.ViewCount > 100
),
FilteredPostDetails AS (
    SELECT 
        PD.*,
        US.Reputation AS AuthorReputation,
        US.TotalUpVotes,
        US.TotalDownVotes,
        US.TotalBadges
    FROM PostDetails PD
    LEFT JOIN UserStats US ON PD.OwnerUserId = US.UserId
    WHERE PD.RN = 1
)
SELECT 
    FPD.PostId,
    FPD.Title,
    FPD.Score,
    FPD.ViewCount,
    FPD.AuthorDisplayName,
    FPD.AuthorReputation,
    FPD.TotalUpVotes,
    FPD.TotalDownVotes,
    FPD.TotalBadges,
    CASE
        WHEN FPD.AnswerCount > 10 THEN 'Hot Topic'
        WHEN FPD.AnswerCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Needs Attention'
    END AS EngagementStatus
FROM FilteredPostDetails FPD
ORDER BY FPD.ViewCount DESC
LIMIT 50;

-- Using a UNION to combine it with another query that fetches posts closed for different reasons
UNION ALL

SELECT 
    PH.PostId,
    'Closed Post' AS Title,
    0 AS Score,
    0 AS ViewCount,
    PH.UserDisplayName AS AuthorDisplayName,
    0 AS AuthorReputation,
    0 AS TotalUpVotes,
    0 AS TotalDownVotes,
    0 AS TotalBadges,
    CASE 
        WHEN PH.Comment IS NOT NULL THEN 'Closed for Reason: ' || PH.Comment
        ELSE 'Closed Without Specified Reason'
    END AS EngagementStatus
FROM PostHistory PH
WHERE PH.PostHistoryTypeId IN (10, 11) -- Closed and Reopened reasons
ORDER BY PH.CreationDate DESC
LIMIT 50;
