WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViewCount,
        COUNT(*) OVER (PARTITION BY pt.Name) AS TotalInCategory,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(SUBSTRING(p.Body FROM '<h1>(.*?)</h1>'), 'No Title') AS ExtractedTitle,
        CASE 
            WHEN p.Body LIKE '%?%' THEN 'Question'
            ELSE 'Answer'
        END AS PostType
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ExtractedTitle,
        rp.TotalInCategory,
        rp.RankByViewCount,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.PostType,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        RankedPosts rp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ExtractedTitle,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    ps.PostType,
    ROUND((ps.UpVoteCount::decimal / NULLIF(ps.TotalInCategory, 0)) * 100, 2) AS UpvotePercentage
FROM 
    PostStatistics ps
WHERE 
    ps.RankByViewCount <= 10
ORDER BY 
    ps.ViewCount DESC,
    ps.OwnerReputation DESC;
