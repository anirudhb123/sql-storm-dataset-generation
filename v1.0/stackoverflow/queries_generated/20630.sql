WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 month')
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Rank,
        tp.TagName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT pt.PostId, t.TagName, COUNT(t.TagName) AS TagCount
         FROM 
             (SELECT PostId, unnest(string_to_array(Tags, '><')) AS TagName FROM Posts) pt
         JOIN 
             Tags t ON pt.TagName = t.TagName
         GROUP BY pt.PostId, t.TagName
         HAVING COUNT(t.TagName) > 2) tp ON rp.PostId = tp.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    t.TagName,
    COUNT(t.PostId) AS PostCount,
    AVG(rp.ViewCount) AS AvgViewCount,
    SUM(rp.UpVoteCount - rp.DownVoteCount) AS NetVoteCount
FROM 
    TaggedPosts t
JOIN 
    RankedPosts rp ON t.PostId = rp.PostId
GROUP BY 
    t.TagName
HAVING 
    AVG(rp.ViewCount) > 100
    AND COUNT(t.PostId) > 1
ORDER BY 
    NetVoteCount DESC
LIMIT 10;

-- Outer join with PostHistory to find closed posts and their latest activity
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.CreationDate AS LastChangeDate,
    ph.Comment AS CloseReason,
    p.AcceptedAnswerId,
    CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' 
        ELSE 'Active' 
    END AS Status,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    ph.CreationDate IS NOT NULL
GROUP BY 
    p.Id, p.Title, ph.CreationDate, ph.Comment, p.AcceptedAnswerId
HAVING 
    COUNT(c.Id) > 5
    OR ph.Comment IS NOT NULL
ORDER BY 
    LastChangeDate DESC;

-- A complex check to ensure no NULL parent posts in answers, yet retaining the hierarchical structure
WITH RecursiveParents AS (
    SELECT 
        p.Id AS ChildPostId,
        p.ParentId,
        ARRAY[p.Id] AS PostPath
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 -- Answers
    UNION ALL
    SELECT 
        p.Id AS ChildPostId,
        p.ParentId,
        rp.PostPath || p.Id
    FROM 
        Posts p
    JOIN 
        RecursiveParents rp ON p.Id = rp.ParentId
)
SELECT 
    rp.PostPath,
    COUNT(*) AS PathLength 
FROM 
    RecursiveParents rp
GROUP BY 
    rp.PostPath
HAVING 
    COUNT(*) > 5;

-- Complex correlation to find users with diverse badge types also correlating to their popularity
SELECT 
    u.DisplayName,
    COUNT(DISTINCT b.Class) AS BadgeCount,
    SUM(u.UpVotes) AS TotalUpVotes,
    SUM(b.Class) AS BadgeImpact
FROM 
    Users u
JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
HAVING 
    BadgeCount >= 3
    AND TotalUpVotes >= 50;

-- Combining multiple logic aspects with string manipulation to derive post types and their metadata
SELECT 
    p.PostTypeId,
    STRING_AGG(DISTINCT 'Tag: ' || t.TagName, ', ') AS Tags,
    SUM(p.ViewCount) AS TotalViews,
    MAX(p.LastActivityDate) AS LastActive,
    MIN(p.CreationDate) AS FirstCreated
