WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        v.PostId, v.VoteTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(SUM(CASE WHEN rv.VoteTypeId = 2 THEN rv.VoteCount ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN rv.VoteTypeId = 3 THEN rv.VoteCount ELSE 0 END), 0) AS Downvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.RankByScore <= 10 OR rp.RankByViews <= 10
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
),
FinalPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        fp.Upvotes,
        fp.Downvotes,
        CASE WHEN fp.Upvotes + fp.Downvotes > 0 THEN (fp.Upvotes * 1.0 / (fp.Upvotes + fp.Downvotes)) ELSE NULL END AS VoteRatio
    FROM 
        FilteredPosts fp
)

SELECT 
    fp.*,
    CASE 
        WHEN VoteRatio IS NULL THEN 'No Votes'
        WHEN VoteRatio >= 0.75 THEN 'Highly Favorable'
        WHEN VoteRatio BETWEEN 0.46 AND 0.74 THEN 'Mixed Opinions'
        ELSE 'Critical'
    END AS VoteSummary
FROM 
    FinalPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 100;

-- Test for edge cases with NULL handling and string aggregation

WITH TagCounts AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        t.IsModeratorOnly IS NULL -- assuming IsModeratorOnly should not affect count
    GROUP BY 
        p.Id
)

SELECT 
    fp.PostId,
    fp.Title,
    COALESCE(tc.Tags, 'No Tags') AS Tags,
    tc.TagCount
FROM 
    FinalPosts fp
LEFT JOIN 
    TagCounts tc ON fp.PostId = tc.PostId
ORDER BY 
    fp.Score DESC;
