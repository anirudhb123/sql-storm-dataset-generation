WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        AVG(COALESCE(v.VoteTypeId, 0)) AS AverageVoteType,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tags_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH ' ' FROM unnest(tags_array))
    WHERE 
        pt.Name IN ('Question', 'Answer')
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Rank,
        rp.CommentCount,
        CASE 
            WHEN rp.AverageVoteType = 0 THEN 'No Votes'
            WHEN rp.AverageVoteType IS NULL THEN 'No Votes Recorded'
            ELSE 'Average Vote Type: ' || CAST(rp.AverageVoteType AS VARCHAR)
        END AS VoteDescription,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    u.DisplayName AS OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.VoteDescription,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
ORDER BY 
    fp.CommentCount DESC, fp.CreationDate DESC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM FilteredPosts) / 2;

-- Investigating outer join with NULL logic corner case
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS UniqueVoteCount,
    AVG(COALESCE(v.VoteTypeId, 0)) AS AvgVoteType
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId OR p.ViewCount IS NULL
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
HAVING 
    AVG(COALESCE(v.VoteTypeId, 0)) < 3
ORDER BY 
    PostCount DESC;

-- Set operator usage to merge result sets from different queries
SELECT 
    'User Contribution Metrics' AS Source,
    u.DisplayName,
    SUM(COALESCE(bp.TotalBadges, 0)) AS TotalBadges,
    COUNT(DISTINCT fp.PostId) AS TotalPosts
FROM 
    Users u
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS TotalBadges 
     FROM Badges 
     GROUP BY UserId) bp ON u.Id = bp.UserId
LEFT JOIN 
    FilteredPosts fp ON u.Id = fp.OwnerUserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName

UNION ALL

SELECT 
    'Post Engagement Details' AS Source,
    p.Title AS DisplayName,
    SUM(b.Class) AS SumBadgeClasses,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    p.Title
HAVING 
    SUM(b.Class) IS NOT NULL
ORDER BY 
    1, 2;
