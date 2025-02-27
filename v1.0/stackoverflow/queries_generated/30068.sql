WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(co.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.AcceptedAnswerId END) AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  -- BountyClose
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
),
UserStatistics AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        u.TotalPosts,
        u.TotalReputation,
        u.TotalBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics u ON rp.OwnerDisplayName = u.DisplayName
    WHERE 
        rp.Rank <= 5  -- Top 5 posts per user
)
SELECT 
    tp.*,
    (SELECT 
         STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM 
         STRING_SPLIT(p.Tags, ',') AS tagNames 
     JOIN 
         Tags t ON t.TagName = LTRIM(RTRIM(tagNames.value))
     WHERE 
         tp.PostID = p.Id) AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostID = p.Id
ORDER BY 
    tp.ViewCount DESC, 
    tp.CreationDate DESC;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level 
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON ph.Id = p.ParentId
)
SELECT 
    ph.Level,
    COUNT(p.Id) AS PostsCount
FROM 
    PostHierarchy ph
LEFT JOIN 
    Posts p ON ph.Id = p.ParentId
GROUP BY 
    ph.Level
ORDER BY 
    ph.Level;

