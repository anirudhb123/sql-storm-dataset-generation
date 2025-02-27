WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 YEAR')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), 
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    t.Id AS PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.UpVotes,
    t.DownVotes,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = t.Id) AS CommentCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = t.Id AND ph.PostHistoryTypeId = 10) AS CloseCount,
    (SELECT STRING_AGG(pt.Name, ', ') FROM PostHistoryTypes pt WHERE pt.Id IN (SELECT DISTINCT ph.PostHistoryTypeId FROM PostHistory ph WHERE ph.PostId = t.Id)) AS PostHistoryTypes
FROM 
    TopPosts t
JOIN 
    Users u ON t.OwnerUserId = u.Id
LEFT JOIN 
    Tags tg ON tg.ExcerptPostId = t.Id
WHERE 
    u.Reputation > 1000
ORDER BY 
    t.Score DESC, t.ViewCount DESC
LIMIT 100;

-- Explanation:
-- 1. The `RankedPosts` CTE calculates ranks for each user's posts from the last year and aggregates upvotes and downvotes for each post.
-- 2. The `TopPosts` CTE filters for the highest-ranked post per user.
-- 3. The final SELECT retrieves detailed information about these top posts, including the owner's reputation, the comment count, closed status, and types of post history modifications.
