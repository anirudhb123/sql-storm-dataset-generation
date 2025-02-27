WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        1 AS Level,
        CAST(p.Title AS VARCHAR(300)) AS PathTitle
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting from Questions

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.PostTypeId,
        r.Level + 1 AS Level,
        CAST(r.PathTitle || ' -> ' || a.Title AS VARCHAR(300)) AS PathTitle
    FROM Posts a
    INNER JOIN RecursivePostCTE r ON a.ParentId = r.PostId
    WHERE a.PostTypeId = 2  -- Only Answers
)
, UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS Reputation
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
)
, ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        DATEDIFF(MINUTE, ph.CreationDate, GETDATE()) AS MinutesSinceClosed
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
)
SELECT 
    DISTINCT r.PostId,
    r.Title,
    p.OwnerDisplayName AS OriginalPoster,
    u.DisplayName AS Answerer,
    u.Reputation AS AnswererReputation,
    us.TotalBounties,
    us.VoteCount,
    us.BadgeCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = r.PostId) AS CommentCount,
    (SELECT AVG(rp.Score) FROM Posts rp WHERE rp.ParentId = r.PostId) AS AverageAnswerScore,
    ch.MinutesSinceClosed,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM RecursivePostCTE r
INNER JOIN Posts p ON p.Id = r.PostId
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN UserStats us ON u.Id = us.UserId
LEFT JOIN PostLinks pl ON pl.PostId = r.PostId
LEFT JOIN Tags t ON t.Id = pl.RelatedPostId
LEFT JOIN ClosedPostHistory ch ON ch.PostId = r.PostId
WHERE p.PostTypeId = 1 -- Only main Questions
AND p.ViewCount > 1000 -- Popular questions
AND ch.MinutesSinceClosed IS NULL  -- Exclude closed questions
GROUP BY 
    r.PostId, r.Title, p.OwnerDisplayName, u.DisplayName, 
    u.Reputation, us.TotalBounties, us.VoteCount, 
    us.BadgeCount, ch.MinutesSinceClosed
ORDER BY 
    p.ViewCount DESC, r.PostId;
