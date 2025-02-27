WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureChanges,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 52) THEN 1 END) AS FeaturedChanges
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.Author,
    p.Rank,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    CASE 
        WHEN p.Rank <= 3 THEN 'Top Ranking Post'
        WHEN p.Rank <= 10 THEN 'Highly Rated Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    COALESCE(pt.TagCount, 0) AS PopularTagCount,
    CASE 
        WHEN ph.ClosureChanges > 0 THEN 'Closed/Modified Post'
        ELSE 'Active Post'
    END AS PostStatus
FROM 
    RankedPosts p
LEFT JOIN 
    PopularTags pt ON p.Title ILIKE '%' || pt.TagName || '%'
LEFT JOIN 
    PostHistoryDetails ph ON p.PostId = ph.PostId
WHERE 
    p.Rank <= 10
ORDER BY 
    p.Score DESC, p.CommentCount DESC;

-- Potential corner cases:
-- 1. Null handling for User or empty Tags.
-- 2. The `ILIKE` can lead to performance issues if the TagName is very wide.
-- 3. The use of `COUNT(*) over()` could allow for even more detailed ranking within subcategories.
