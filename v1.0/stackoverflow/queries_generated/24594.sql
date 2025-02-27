WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(vote.VoteTypeId = 2) AS UpVoteCount,
        SUM(vote.VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes vote ON vote.PostId = p.Id
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    CASE 
        WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
        WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionStatus,
    CASE 
        WHEN rp.Score > 100 THEN 'Hot'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Trending'
        ELSE 'Cold'
    END AS PopularityStatus,
    (SELECT 
        COUNT(DISTINCT b.UserId) 
     FROM Badges b 
     WHERE b.UserId IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
    ) AS UniqueBadgeCount,
    (SELECT STRING_AGG(DISTINCT lt.Name, ', ') 
     FROM LinkTypes lt 
     JOIN PostLinks pl ON pl.LinkTypeId = lt.Id 
     WHERE pl.PostId = rp.PostId
    ) AS RelatedPostTypes
FROM RankedPosts rp
WHERE rp.rn = 1
AND rp.Score IS NOT NULL
AND rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE ViewCount IS NOT NULL)
ORDER BY rp.Score DESC, rp.ViewCount DESC;

-- Find the posts that have been edited the most times and their related information
WITH EditCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM PostHistory
    WHERE PostHistoryTypeId IN (4, 5, 6)  -- Type 4 = Edit Title, 5 = Edit Body, 6 = Edit Tags
    GROUP BY PostId
    HAVING COUNT(*) > 2  -- Only consider those with more than two edits
)
SELECT 
    p.Id AS PostId,
    p.Title,
    ec.EditCount,
    (
        SELECT STRING_AGG(DISTINCT CONCAT(uh.DisplayName, ' (', uh.Reputation, ')'), '; ') 
        FROM Users uh 
        JOIN PostHistory ph ON ph.UserId = uh.Id 
        WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5, 6)
    ) AS Editors,
    COALESCE(
        (SELECT MIN(ph.CreationDate) 
         FROM PostHistory ph 
         WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5, 6)
        ), 'Never Edited') AS FirstEditDate
FROM Posts p
JOIN EditCounts ec ON ec.PostId = p.Id
ORDER BY ec.EditCount DESC, p.Title ASC;

-- Final report combining different metrics with NULL logical conditions
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(SUM(p.ViewCount), 0) AS TotalPostViews,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmounts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
    COALESCE(MAX(b.Date), 'No Badge') AS LastBadgeDate,
    COALESCE(STRING_AGG(DISTINCT b.Name, ', '), 'No Badges') AS Badges
FROM Users u
LEFT JOIN Posts p ON p.OwnerUserId = u.Id
LEFT JOIN Votes v ON v.UserId = u.Id
LEFT JOIN Badges b ON b.UserId = u.Id
GROUP BY u.Id, u.DisplayName
HAVING COALESCE(SUM(p.ViewCount), 0) > 1000
ORDER BY TotalPostViews DESC, UserId;

