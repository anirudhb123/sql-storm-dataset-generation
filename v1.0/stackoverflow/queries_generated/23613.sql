WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        COUNT(DISTINCT PostId) AS PostCount,
        SUM(Reputation) OVER (PARTITION BY Id) AS TotalReputation,
        RANK() OVER (ORDER BY COUNT(DISTINCT PostId) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
BadgesSummary AS (
    SELECT 
        UserId,
        STRING_AGG(Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount,
        MAX(Date) AS LastBadgeDate
    FROM Badges
    GROUP BY UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        JSON_AGG(DISTINCT ph.Comment) AS CloseReasonComments
    FROM PostHistory ph
    GROUP BY ph.PostId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(AnswerCount, 0) AS AnswerCount,
        COALESCE(CommentCount, 0) AS CommentCount,
        p.CreationDate,
        CASE 
            WHEN COALESCE(AnswerCount, 0) > 0 THEN 'Has Answers'
            ELSE 'No Answers'
        END AS AnswerStatus,
        COALESCE(MAX(phd.LastChangeDate), 'never') AS LastChange
    FROM Posts p
    LEFT JOIN PostHistoryDetails phd ON p.Id = phd.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS AnswerCount, 
            SUM(CommentCount) AS CommentCount
        FROM Posts 
        WHERE PostTypeId = 2
        GROUP BY PostId
    ) sub ON p.Id = sub.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, AnswerCount, CommentCount
)
SELECT 
    u.DisplayName,
    r.PostCount,
    b.BadgeNames,
    b.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate,
    ps.AnswerStatus,
    pd.CloseReopenCount,
    pd.CloseReasonComments
FROM RankedUsers r
JOIN Users u ON r.Id = u.Id
LEFT JOIN BadgesSummary b ON u.Id = b.UserId
LEFT JOIN PostStats ps ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
LEFT JOIN PostHistoryDetails pd ON ps.PostId = pd.PostId
WHERE r.PostRank <= 10
ORDER BY r.PostCount DESC, u.DisplayName;
