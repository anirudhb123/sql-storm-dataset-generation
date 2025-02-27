WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN p.Id END) AS AcceptedAnswerCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
VoteDetails AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
RecentPostEdits AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY ph.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
    COALESCE(vd.VoteCount, 0) AS VoteCount,
    COALESCE(vd.Upvotes, 0) AS Upvotes,
    COALESCE(vd.Downvotes, 0) AS Downvotes,
    COALESCE(rpe.EditCount, 0) AS RecentEditCount,
    rpe.FirstEditDate,
    rpe.LastEditDate,
    ut.BadgeCount
FROM UserReputation ut
LEFT JOIN PostStats ps ON ut.UserId = ps.OwnerUserId
LEFT JOIN VoteDetails vd ON ut.UserId = vd.UserId
LEFT JOIN RecentPostEdits rpe ON ut.UserId = rpe.UserId
WHERE ut.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY ut.Reputation DESC, uv.BadgeCount DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

In this query:
- **CTEs** aggregate user reputation and accumulate statistics about posts, votes, and recent edits.
- **COALESCE** handles potential NULL values from left joins.
- The final selection filters by a condition related to the average user reputation.
- The output is sorted by reputation and badge count while implementing pagination with OFFSET and FETCH.
