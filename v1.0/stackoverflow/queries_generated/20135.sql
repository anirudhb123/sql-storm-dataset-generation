WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'No Reputation'
            WHEN Reputation < 100 THEN 'Novice'
            WHEN Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(vote.VoteTypeId = 2) AS UpVoteCount, 
        SUM(vote.VoteTypeId = 3) AS DownVoteCount,
        p.CreationDate,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate))/3600 AS AgeInHours
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes vote ON p.Id = vote.PostId
    GROUP BY p.Id, p.CreationDate
),
PostLinksStatistics AS (
    SELECT 
        pl.PostId AS PostId,
        COUNT(pl.RelatedPostId) AS TotalLinks,
        COUNT(DISTINCT pl.LinkTypeId) AS UniqueLinkTypes
    FROM PostLinks pl
    GROUP BY pl.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseReasonCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
),
TopPostStats AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.AgeInHours,
        COALESCE(pls.TotalLinks, 0) AS TotalLinks,
        COALESCE(cps.CloseReasonCount, 0) AS CloseReasonCount,
        CASE 
            WHEN ps.DownVoteCount > ps.UpVoteCount THEN 'Negatively Rated'
            WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'Positively Rated'
            ELSE 'Neutral'
        END AS PostRating
    FROM PostStatistics ps
    LEFT JOIN PostLinksStatistics pls ON ps.PostId = pls.PostId
    LEFT JOIN ClosedPosts cps ON ps.PostId = cps.PostId
    WHERE ps.AgeInHours < 720 -- considering posts younger than 30 days
),
RankedPosts AS (
    SELECT 
        tps.PostId,
        tps.CommentCount,
        tps.TotalLinks,
        tps.PostRating,
        ROW_NUMBER() OVER (ORDER BY tps.UpVoteCount DESC, tps.CommentCount DESC) AS Rank
    FROM TopPostStats tps
)

SELECT 
    up.Id AS UserId,
    up.ReputationLevel,
    rp.PostId,
    rp.CommentCount,
    rp.TotalLinks,
    rp.PostRating
FROM UserReputation up
JOIN RankedPosts rp ON rp.PostId IN (
    SELECT DISTINCT p.Id 
    FROM Posts p 
    WHERE p.OwnerUserId = up.UserId
)
WHERE up.ReputationLevel <> 'No Reputation'
AND EXISTS (
    SELECT 1 
    FROM Posts p
    WHERE p.OwnerUserId = up.UserId 
    AND p.CreatedAt < CURRENT_TIMESTAMP - INTERVAL '1 year'
)
ORDER BY up.Reputation DESC, rp.PostRating DESC;
