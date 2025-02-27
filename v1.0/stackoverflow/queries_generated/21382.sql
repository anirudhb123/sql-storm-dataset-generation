WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) as RankPerType,
        COUNT(c.Id) OVER (PARTITION BY p.Id) as CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Reputation,
        rp.RankPerType,
        ub.BadgeCount,
        ub.BadgeNames,
        CASE 
            WHEN rp.RankPerType <= 5 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    COALESCE(pm.BadgeCount, 0) AS BadgeCount,
    ARRAY_LENGTH(string_to_array(pm.BadgeNames, ', '), 1) AS BadgeCountDistinct,
    CASE 
        WHEN pm.PostCategory = 'Top Post' THEN 'Highly Recommended'
        ELSE 'Needs Improvement'
    END AS Recommendation,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pm.PostId AND v.VoteTypeId = 3) AS DownVotesCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pm.PostId AND v.VoteTypeId = 2) AS UpVotesCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, '><'))::int[]
     WHERE p.Id = pm.PostId) AS TagsList
FROM 
    PostMetrics pm
WHERE 
    pm.Reputation > 1000
ORDER BY 
    pm.Score DESC, 
    pm.ViewCount DESC
LIMIT 50;

-- Notes:
-- This query constructs a multi-CTE approach to evaluate posts from the last year, qualifying them based on various metrics such as rank, user reputation, and badge counts.
-- STRING_AGG and ARRAY_LENGTH functions are leveraged to create complex aggregations for badge names, showcasing how users' badges relate to their posts.
-- The processing uses correlated subqueries to fetch the counts of upvotes and downvotes separately.
-- Tags are processed using string manipulations and array operations, demonstrating intricate handling of text fields.
