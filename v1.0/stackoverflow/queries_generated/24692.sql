WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        CASE 
            WHEN SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) > SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) 
                THEN 'Net Positive' 
                ELSE 'Net Neutral or Negative' 
        END AS VoteBalance
    FROM Users AS U
    LEFT JOIN Votes AS V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COALESCE(CP.CommentCount, 0) AS CommentCount,
        COALESCE(AC.AnswerCount, 0) AS TotalAnswers,
        PT.Name AS PostType
    FROM Posts AS P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) AS CP ON P.Id = CP.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(Id) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) AS AC ON P.Id = AC.ParentId
    JOIN PostTypes AS PT ON P.PostTypeId = PT.Id
),
PostHistoryFiltered AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        MAX(PH.CreationDate) OVER (PARTITION BY PH.PostId) AS LastActivity
    FROM PostHistory AS PH
    WHERE PH.PostHistoryTypeId IN (10, 11) AND PH.UserId IS NOT NULL
),
ActivePostStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.OwnerUserId,
        PS.Score,
        PS.ViewCount,
        PS.CommentCount,
        PS.TotalAnswers,
        PHF.PostHistoryTypeId,
        PHF.LastActivity
    FROM PostStats AS PS
    LEFT JOIN PostHistoryFiltered AS PHF ON PS.PostId = PHF.PostId
    WHERE Phf.LastActivity IS NOT NULL
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    A.PS.PostId,
    A.Title,
    A.Score,
    A.ViewCount,
    A.CommentCount,
    A.TotalAnswers,
    A.LastActivity,
    UPS.VoteBalance,
    CASE 
        WHEN A.ViewCount > 100 THEN 'Highly Viewed' 
        ELSE 'Moderate or Low Views' 
    END AS ViewCategory
FROM UserVoteStats AS UPS
JOIN ActivePostStats AS A ON A.OwnerUserId = UPS.UserId
WHERE UPS.TotalVotes > 10
ORDER BY A.Score DESC, UPS.TotalVotes DESC
OFFSET (SELECT COUNT(*) FROM Users) * 0.1 LIMIT 10;

