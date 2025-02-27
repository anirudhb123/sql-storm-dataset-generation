WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY p.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.Views,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.NetVotes,
    CASE 
        WHEN rp.CommentCount > 10 THEN 'Very Active'
        WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    CASE 
        WHEN rp.NetVotes > 50 THEN 'Highly Regarded'
        WHEN rp.NetVotes BETWEEN 20 AND 50 THEN 'Regarded'
        ELSE 'Needs Improvement'
    END AS ReputationLevel
FROM Users u
JOIN RankedPosts rp ON u.Id = rp.PostRank
WHERE 
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = u.Id AND b.Class = 1) > 0
    AND rp.PostRank = 1
ORDER BY u.Reputation DESC, rp.Score DESC;

-- Next, find the posts that have links to questions with the most votes from users who own gold badges
WITH GoldBadgePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(v.VoteTypeId = 2) AS UpVotes
    FROM Posts p
    JOIN Votes v ON p.Id = v.PostId
    JOIN Badges b ON b.UserId = p.OwnerUserId
    WHERE b.Class = 1 
    GROUP BY p.Id, p.Title
)

SELECT 
    lp.PostId,
    lp.Title,
    lb.UpVotes,
    lp.RelatedPostId
FROM PostLinks lp
JOIN GoldBadgePosts lb ON lp.RelatedPostId = lb.PostId
WHERE lb.UpVotes > (
    SELECT AVG(UpVotes) FROM GoldBadgePosts
)
ORDER BY lb.UpVotes DESC;

-- Finally, let's see which tags are associated with posts that have been closed, also showing the breakdown of 
-- how many posts of each tag are closed and the ratio of closed posts to total posts.
SELECT 
    t.TagName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN p.Id END) AS ClosedPosts,
    CASE 
        WHEN COUNT(DISTINCT p.Id) > 0 THEN 
            COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN p.Id END) * 1.0 / COUNT(DISTINCT p.Id)
        ELSE 0 
    END AS ClosedPostRatio
FROM Tags t
JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
GROUP BY t.TagName
HAVING ClosedPostRatio > 0.1
ORDER BY ClosedPostRatio DESC;
