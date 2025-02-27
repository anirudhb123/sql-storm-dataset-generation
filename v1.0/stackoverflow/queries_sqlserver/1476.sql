
;WITH UserScore AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        CAST(UpVotes AS INT) - CAST(DownVotes AS INT) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        MAX(b.Date) AS LastBadgeDate,
        b.Class AS BadgeClass
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
    GROUP BY p.Id, p.Score, p.ViewCount, p.AcceptedAnswerId, b.Class
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        CR.Name AS CloseReason
    FROM PostHistory ph
    JOIN CloseReasonTypes CR ON CAST(ph.Comment AS INT) = CR.Id
    WHERE ph.PostHistoryTypeId = 10 
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Location,
    P.Title,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    COALESCE(CP.CloseDate, NULL) AS ClosedDate,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
    CASE 
        WHEN PS.BadgeClass IS NOT NULL THEN 'Badge Earned'
        ELSE 'No Badge'
    END AS BadgeStatus
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
JOIN PostStats PS ON P.Id = PS.PostId
LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
WHERE U.Reputation > 1000
AND PS.CommentCount > 5
ORDER BY U.Reputation DESC, PS.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
