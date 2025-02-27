WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.OwnerUserId) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.OwnerUserId) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.ViewRank <= 3 THEN 'Top View'
            ELSE 'Regular View'
        END AS ViewCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 0 AND 
        rp.LastActivityDate IS NOT NULL
),
PostDetails AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.ViewCount,
        fp.ViewCategory,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COALESCE(ph.ProfileImageUrl, 'https://default.image.url') AS ProfileImageUrl
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Badges b ON b.UserId = fp.OwnerUserId AND b.Class = 1
    LEFT JOIN 
        Users ph ON ph.Id = fp.OwnerUserId
)
SELECT 
    pd.Title,
    pd.ViewCount,
    pd.ViewCategory,
    COUNT(DISTINCT c.Id) AS TotalComments,
    pd.BadgeName,
    pd.ProfileImageUrl
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
WHERE 
    pd.ViewCategory = 'Top View'
GROUP BY 
    pd.Title, pd.ViewCount, pd.ViewCategory, pd.BadgeName, pd.ProfileImageUrl
ORDER BY 
    pd.ViewCount DESC
LIMIT 10;

-- Additional benchmark query: User engagement metrics
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS TotalVotes,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.TotalVotes,
    ue.PostsCreated,
    ue.TotalBadgePoints,
    CASE 
        WHEN ue.TotalBadgePoints > 5 THEN 'Expert'
        WHEN ue.TotalBadgePoints BETWEEN 2 AND 5 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    UserEngagement ue
WHERE 
    ue.TotalVotes > 10
ORDER BY 
    ue.TotalBadgePoints DESC, ue.TotalVotes DESC;

-- Complex interaction analysis between different post types
SELECT
    pt.Name AS PostType,
    COUNT(DISTINCT p.Id) AS NumberOfPosts,
    AVG(p.ViewCount) AS AvgViewCount,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
GROUP BY 
    pt.Name
HAVING 
    COUNT(DISTINCT p.Id) > 50
ORDER BY 
    AvgViewCount DESC;
