WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId IN (1, 2) AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostMetadata AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.PostRank,
        rp.Upvotes,
        rp.Downvotes,
        COALESCE(CAST(SUM(b.Class = 1) OVER (PARTITION BY rp.OwnerUserId) AS INT), 0) AS GoldBadges,
        COALESCE(CAST(SUM(b.Class = 2) OVER (PARTITION BY rp.OwnerUserId) AS INT), 0) AS SilverBadges,
        CASE 
            WHEN SUM(b.Class = 3) OVER (PARTITION BY rp.OwnerUserId) IS NULL THEN 0
            ELSE SUM(b.Class = 3) OVER (PARTITION BY rp.OwnerUserId)
        END AS BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId
),
PostEngagement AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.PostRank,
        pm.Upvotes,
        pm.Downvotes,
        CASE 
            WHEN pm.Upvotes + pm.Downvotes > 0 THEN (pm.Upvotes::FLOAT / (pm.Upvotes + pm.Downvotes)) 
            ELSE NULL 
        END AS UpvoteRatio,
        PM.OwnerUserId,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pm.PostId) AS CommentCount
    FROM 
        PostMetadata pm
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.ViewCount,
    pe.PostRank,
    pe.Upvotes,
    pe.Downvotes,
    pe.UpvoteRatio,
    pe.CommentCount,
    CASE
        WHEN pe.UpvoteRatio IS NULL THEN 'No votes yet'
        WHEN pe.UpvoteRatio >= 0.75 THEN 'Highly upvoted'
        WHEN pe.UpvoteRatio >= 0.5 THEN 'Moderately upvoted'
        ELSE 'Mostly downvoted'
    END AS EngagementStatus
FROM 
    PostEngagement pe
WHERE 
    pe.Upvotes > 0 OR pe.Downvotes > 0
ORDER BY 
    pe.PostRank ASC
LIMIT 100;

This SQL query dives into performance benchmarking by exploring a wide range of constructs including Common Table Expressions (CTEs), window functions, conditional logic, and aggregates. The query first ranks posts by view count, accumulates different types of votes, and calculates user badge counts before finally selecting the most engaging posts based on user interaction. It also incorporates nuanced metrics like the Upvote Ratio and categorizes posts based on engagement levels, providing a rich dataset for performance analysis.
