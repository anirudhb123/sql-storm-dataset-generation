WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank,
        COALESCE(SUM(P.ViewCount) FILTER (WHERE P.PostTypeId = 1), 0) AS TotalQuestionViews,
        COALESCE(SUM(P.ViewCount) FILTER (WHERE P.PostTypeId = 2), 0) AS TotalAnswerViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN V.VoteTypeId IN (6, 10) THEN 1 END) AS CloseVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
RecentEditHistory AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PH.Comment, '; ') AS EditComments
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5)
    GROUP BY PH.PostId
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.Rank,
    PS.Title,
    PS.ViewCount,
    PS.Upvotes,
    PS.Downvotes,
    PS.CloseVotes,
    COALESCE(RE.LastEditDate, 'Never') AS LastEditDate,
    COALESCE(RE.EditComments, 'No edits made.') AS EditComments,
    CASE 
        WHEN RU.Reputation >= 1000 THEN 'Veteran'
        WHEN RU.Reputation >= 500 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel,
    (CASE 
        WHEN PS.CloseVotes > 0 THEN 'Closed' 
        ELSE 'Open' 
    END) AS PostStatus,
    DATE_PART('dow', NOW()) AS CurrentDay, 
    (SELECT COUNT(*) FROM Users U2 WHERE U2.Reputation > RU.Reputation) AS MoreReputableUsers
FROM RankedUsers RU
JOIN PostStats PS ON RU.UserId = PS.OwnerUserId
LEFT JOIN RecentEditHistory RE ON PS.PostId = RE.PostId
WHERE RU.Reputation IS NOT NULL
ORDER BY RU.Rank
LIMIT 10 OFFSET 5;
