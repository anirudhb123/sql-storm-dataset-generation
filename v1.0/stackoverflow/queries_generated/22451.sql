WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) as HasUpvote,
        MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) as HasDownvote
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),

FilteredData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        u.UserId,
        r.Reputation,
        u.BadgeCount,
        rp.RankScore,
        CASE 
            WHEN rp.HasUpvote = 1 AND rp.HasDownvote = 1 THEN 'Mixed'
            WHEN rp.HasUpvote = 1 THEN 'Upvoted'
            ELSE 'No Upvotes'
        END AS VoteStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation u ON u.UserId = rp.OwnerUserId
    WHERE 
        (u.Reputation > 100 OR u.BadgeCount > 5)  -- Only highly reputable users
        AND rp.RankScore <= 5  -- Top 5 ranked posts per user
)

SELECT 
    fd.PostId,
    fd.Title,
    fd.CreationDate,
    fd.Score,
    fd.ViewCount,
    fd.CommentCount,
    fd.Reputation,
    fd.BadgeCount,
    fd.VoteStatus,
    CASE 
        WHEN fd.CommentCount IS NULL THEN 'No Comments Yet'
        WHEN fd.CommentCount > 10 THEN 'Many Comments'
        ELSE 'Some Comments'
    END AS CommentsStatus,
    CASE 
        WHEN DATE_PART('dow', fd.CreationDate) IN (0, 6) THEN 'Weekend Post'
        ELSE 'Weekday Post'
    END AS PostingDayType
FROM 
    FilteredData fd
WHERE 
    fd.RankScore < 3  -- Posts with the highest engagement
ORDER BY 
    fd.Score DESC, 
    fd.ViewCount DESC
LIMIT 10;

-- Understanding the corner cases and bizarre SQL semantics:
-- 1. Using DENSE_RANK() allows us to handle ties effectively.
-- 2. Case logic prioritizes vote presence and combines it into readable categorizations.
-- 3. NULL handling in CommentCount produces user-friendly messages.
-- 4. The filter on user reputation and badge count tackles query complexity indirectly, 
--    giving emphasis on top contributors. 
-- 5. The final WHERE clause ensures we only consider top engaged posts to narrow down the 
--    focus on quality interactions amidst a potentially large result set.
