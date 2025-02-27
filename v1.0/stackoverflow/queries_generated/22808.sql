WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) FILTER (WHERE c.Score > 0) AS PositiveCommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpvote,
        MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HasDownvote
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days' -- focusing on recent posts
    GROUP BY 
        p.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING(tag.TagName FROM 2 FOR LENGTH(tag.TagName)-2)) AS CleanTagName,
        SUM(tag.Count) AS TagUsage
    FROM 
        Tags tag
    WHERE 
        tag.IsModeratorOnly = 0
    GROUP BY 
        CleanTagName
    HAVING 
        SUM(tag.Count) > 100
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.PositiveCommentCount,
        pt.Name AS PostTypeName,
        CASE 
            WHEN rp.HasUpvote = 1 AND rp.HasDownvote = 0 THEN 'Upvoted'
            WHEN rp.HasDownvote = 1 AND rp.HasUpvote = 0 THEN 'Downvoted'
            ELSE 'Neutral'
        END AS VoteStatus,
        ARRAY_AGG(DISTINCT pt.TagName) AS RelatedTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        PostTags pt ON p.Id = pt.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.OwnerDisplayName, rp.HasUpvote, rp.HasDownvote
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.Score,
    fp.CreationDate,
    fp.PositiveCommentCount,
    fp.VoteStatus,
    COALESCE(ptv.TagUsage, 0) AS PopularityScore
FROM 
    FilteredPosts fp
LEFT JOIN 
    PopularTags ptv ON fp.RelatedTags && ARRAY[ptv.CleanTagName] -- using && (array overlap) operator to match tags
WHERE 
    fp.VoteStatus = 'Upvoted' OR
    (fp.PositiveCommentCount > 5 AND fp.Score > 10) -- specific conditions to filter interesting posts
ORDER BY 
    fp.Score DESC, -- ordering by score for a leaderboard effect
    fp.PositiveCommentCount DESC
LIMIT 100; -- limit the results for performance benchmarking
