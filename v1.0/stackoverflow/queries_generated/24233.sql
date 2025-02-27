WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Body,
        rp.OwnerName,
        rp.RankByDate,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score' 
            WHEN rp.Score > 0 THEN 'Positive Score' 
            ELSE 'Negative Score' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByDate <= 5
),
PostViewStats AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON fp.PostId = v.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount
)
SELECT 
    pvs.PostId,
    pvs.Title,
    pvs.CreationDate,
    pvs.ViewCount,
    pvs.TotalComments,
    (pvs.TotalUpVotes - pvs.TotalDownVotes) AS NetVotes,
    CASE 
        WHEN pvs.ViewCount > 1000 THEN 'High Engagement'
        WHEN pvs.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostViewStats pvs
ORDER BY 
    NetVotes DESC, 
    pvs.ViewCount DESC 
LIMIT 10;

-- Generate a summary of user activity
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
    COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
    COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT cp.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments cp ON u.Id = cp.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 10 -- only users with more than 10 posts
    AND SUM(b.Class) IS NOT NULL
ORDER BY 
    u.Reputation DESC 
LIMIT 5;

-- Display posts with complex join involving links and closures
SELECT 
    p.Id AS PostId,
    p.Title,
    l.RelatedPostId,
    CASE 
        WHEN l.LinkTypeId = 1 THEN 'Linked'
        WHEN l.LinkTypeId = 3 THEN 'Duplicate'
        ELSE 'Other Link Type'
    END AS LinkType,
    ph.Comment AS CloseReason
FROM 
    Posts p
JOIN 
    PostLinks l ON p.Id = l.PostId
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11) -- Close/Reopen history
WHERE 
    p.Id IN (SELECT RelatedPostId FROM PostLinks WHERE LinkTypeId = 3) 
ORDER BY 
    p.CreationDate DESC;
