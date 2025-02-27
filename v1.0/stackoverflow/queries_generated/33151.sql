WITH RecursiveTopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
            AND p.Score > 0
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        RecursiveTopPosts r ON p.OwnerUserId = r.OwnerUserId
)
, UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
, PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        u.DisplayName AS EditorName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    p.Title AS QuestionTitle,
    u.DisplayName AS AuthorName,
    ub.TotalBadges AS AuthorBadges,
    ub.HighestBadgeClass,
    RANK() OVER (ORDER BY p.Score DESC) AS PostRank,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag
        JOIN Tags t ON t.TagName = TRIM(BOTH ' ' FROM tag)) AS Tags,
    phd.PostHistoryTypeId,
    phd.CreationDate AS EditDate,
    phd.EditorName,
    phd.Comment AS EditComment
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON p.Id = phd.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 month'
    AND ub.TotalBadges > 1
ORDER BY 
    p.Score DESC, 
    ph.CreationDate DESC NULLS LAST
LIMIT 100;
