WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') 
        AND p.PostTypeId = 1 -- Considering only Questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpvoteCount, -- Upvotes only
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownvoteCount -- Downvotes only
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate < (CURRENT_DATE - INTERVAL '2 years') -- Active users for more than 2 years
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT pht.Name) AS HistoryTypes,
        COUNT(*) AS TotalChanges
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= (CURRENT_DATE - INTERVAL '6 months') -- Recent changes
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.DisplayName,
    ua.QuestionCount,
    ua.CommentCount,
    ua.UpvoteCount,
    ua.DownvoteCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pha.HistoryTypes,
    pha.TotalChanges
FROM 
    UserActivity ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.PostRank <= 5
LEFT JOIN 
    PostHistoryAggregate pha ON rp.PostId = pha.PostId
WHERE 
    ua.UpvoteCount > ua.DownvoteCount
ORDER BY 
    ua.QuestionCount DESC, 
    rp.Score DESC
LIMIT 50;

-- This query evaluates:
-- 1. A ranked list of the top-scoring posts by each user (over the last year).
-- 2. User activity for users created over 2 years ago, counting their questions, comments, and vote activities.
-- 3. Aggregates post history types and counts for recent changes in the posts.
-- 4. Filters out users who have more upvotes than downvotes and limits to 50 entries for efficiency.
