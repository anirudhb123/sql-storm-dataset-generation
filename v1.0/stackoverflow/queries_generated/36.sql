WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
HighScoringUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(p.Score) > 100
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        p.Title,
        ph.CreationDate,
        ph.Comment,
        p.AcceptedAnswerId,
        ph.PostHistoryTypeId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    GROUP BY ph.PostId, ph.UserId, p.Title, ph.AcceptedAnswerId, ph.Comment, ph.PostHistoryTypeId
)
SELECT 
    r.Title AS PostTitle,
    r.CreationDate AS PostCreationDate,
    r.Score AS PostScore,
    r.CommentCount,
    hu.DisplayName AS HighScoringUser,
    hu.TotalScore,
    hu.PostCount,
    pd.ClosedDate,
    pd.ReopenedDate
FROM RankedPosts r
JOIN HighScoringUsers hu ON r.OwnerUserId = hu.UserId
LEFT JOIN PostHistoryDetails pd ON r.PostId = pd.PostId
WHERE r.rn = 1
  AND r.Score > 10
  AND COALESCE(pd.ClosedDate, pd.ReopenedDate) IS NOT NULL
ORDER BY r.Score DESC, hu.TotalScore DESC
LIMIT 50;

