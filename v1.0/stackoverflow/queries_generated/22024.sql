WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE PostRank <= 5
),
PostBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS UserBadges
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    WHERE 
        u.Reputation > 5000
    GROUP BY 
        b.UserId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.Upvotes,
    tp.Downvotes,
    tp.CommentCount,
    COALESCE(pb.UserBadges, 'No Badges') AS TopUserBadges
FROM 
    TopPosts tp
LEFT JOIN 
    PostBadges pb ON tp.OwnerUserId = pb.UserId
WHERE 
    tp.Score > 0
AND 
    tp.ViewCount IS NOT NULL
AND 
    EXISTS (
        SELECT 1
        FROM PostHistory ph
        WHERE ph.PostId = tp.PostId
        AND ph.CreationDate > (SELECT MAX(CreationDate) FROM PostHistory WHERE PostHistoryTypeId = 12 AND PostId = tp.PostId)
    )
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

WITH RecentClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
        AND ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    rcp.PostId,
    rcp.Title,
    COUNT(c.Id) AS CloseComments,
    rcp.ClosedDate,
    rcp.CloseReason
FROM 
    RecentClosedPosts rcp
LEFT JOIN 
    Comments c ON rcp.PostId = c.PostId
GROUP BY 
    rcp.PostId, rcp.Title, rcp.ClosedDate, rcp.CloseReason
HAVING 
    COUNT(DISTINCT c.UserId) > 1;

WITH TagsInfo AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(b.Count, 0)) AS TotalExcerpts
    FROM
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Posts b ON t.ExcerptPostId = b.Id
    GROUP BY 
        t.TagName
)
SELECT 
    t.TagName,
    t.PostCount,
    t.TotalExcerpts,
    CASE
        WHEN t.PostCount > 100 THEN 'Highly Active Tag'
        WHEN t.PostCount BETWEEN 50 AND 100 THEN 'Moderately Active Tag'
        ELSE 'Less Active Tag'
    END AS ActivityLevel
FROM 
    TagsInfo t
WHERE 
    t.TotalExcerpts IS NOT NULL
ORDER BY 
    t.TotalExcerpts DESC;

-- It's possible to run comparative analysis between Post Types
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    pt.Name
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    AverageScore DESC;

-- Final review of all outer joins
