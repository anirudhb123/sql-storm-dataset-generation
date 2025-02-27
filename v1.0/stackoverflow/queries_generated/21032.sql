WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        FIRST_VALUE(u.DisplayName) OVER (PARTITION BY p.Id ORDER BY p.CreationDate) AS FirstEditor
    FROM 
        Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN PostHistory ph ON p.Id = ph.PostId
        LEFT JOIN Users u ON p.LastEditorUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.TotalBounty,
        ps.CommentCount,
        ps.EditCount,
        RANK() OVER (ORDER BY ps.Score DESC, ps.TotalBounty DESC) AS PostRank,
        CASE 
            WHEN ps.CommentCount = 0 THEN 'No Comments'
            WHEN ps.CommentCount BETWEEN 1 AND 5 THEN 'Few Comments'
            ELSE 'Many Comments'
        END AS CommentCategory
    FROM 
        PostStats ps
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.TotalBounty,
    rp.CommentCount,
    rp.EditCount,
    rp.PostRank,
    rp.CommentCategory,
    CASE 
        WHEN rp.EditCount > 0 THEN 'Edited'
        ELSE 'Not Edited' 
    END AS EditStatus,
    CASE 
        WHEN rp.TotalBounty IS NULL THEN 'No Bounty'
        ELSE 'Has Bounty'
    END AS BountyStatus
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 10 -- Top 10 posts
ORDER BY 
    rp.PostRank;

-- Further queries to fetch related Links and Badges for top 10 posts
SELECT 
    rp.PostId,
    pl.RelatedPostId,
    lt.Name AS LinkType
FROM 
    RankedPosts rp
    JOIN PostLinks pl ON rp.PostId = pl.PostId
    JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
WHERE 
    rp.PostRank <= 10;

-- Fetch user badges related to posts by first editor of top 10 posts
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    b.Name AS BadgeName,
    b.Date AS BadgeDate
FROM 
    RankedPosts rp
    JOIN Users u ON rp.FirstEditor = u.DisplayName
    LEFT JOIN Badges b ON u.Id = b.UserId
WHERE 
    rp.PostRank <= 10
ORDER BY 
    b.Date DESC;

-- Inner query to calculate distinct tags for the top 10 posts
SELECT 
    rp.PostId,
    COUNT(DISTINCT t.TagName) AS DistinctTagCount
FROM 
    RankedPosts rp
    JOIN Posts p ON rp.PostId = p.Id
    CROSS JOIN LATERAL string_to_array(p.Tags, ',') AS tag
    JOIN Tags t ON tag = t.TagName
WHERE 
    rp.PostRank <= 10
GROUP BY 
    rp.PostId;
