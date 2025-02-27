WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting point: Questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.LastActivityDate,
        a.OwnerUserId,
        a.Score,
        a.ViewCount,
        r.Depth + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursiveCTE r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2  -- Answers to Questions
),
FilteredCTE AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Depth,
        r.CreationDate,
        r.LastActivityDate,
        r.Score,
        r.ViewCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        COALESCE(b.Id, 0) AS BadgeId,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COUNT(c.Id) AS CommentsCount,
        COUNT(v.Id) AS VotesCount
    FROM 
        RecursiveCTE r
    LEFT JOIN 
        Users u ON r.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    LEFT JOIN 
        Votes v ON r.PostId = v.PostId
    GROUP BY 
        r.PostId, r.Title, r.Depth, r.CreationDate, r.LastActivityDate, r.Score, r.ViewCount, u.DisplayName, b.Id, b.Name
),
RankedPosts AS (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (PARTITION BY f.Depth ORDER BY f.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY f.ViewCount DESC) AS RankViews
    FROM 
        FilteredCTE f
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Depth,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.BadgeId,
    rp.BadgeName,
    rp.CommentsCount,
    rp.VotesCount,
    rp.RankScore,
    rp.RankViews
FROM 
    RankedPosts rp
WHERE 
    rp.RankScore <= 10  -- Top 10 per depth
    AND rp.RankViews <= 10  -- Top viewed posts
ORDER BY 
    rp.Depth, rp.Score DESC;
