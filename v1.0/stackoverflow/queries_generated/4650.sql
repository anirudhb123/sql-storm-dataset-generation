WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.Score,
        pm.ViewCount,
        pm.CommentCount,
        pm.UpVotes,
        pm.DownVotes,
        CASE 
            WHEN pm.UserPostRank < 5 THEN 'Top Contributor' 
            ELSE 'Contributor' 
        END AS ContributorLevel
    FROM 
        PostMetrics pm
    WHERE 
        pm.ViewCount > 100
)
SELECT 
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    COALESCE(pm.ContributorLevel, 'New Contributor') AS ContributorLevel
FROM 
    TopPosts pm
WHERE 
    pm.CommentCount > 0
AND 
    pm.UpVotes - pm.DownVotes >= 5
ORDER BY 
    pm.Score DESC
LIMIT 10;

-- Find posts modified more than once, including the last edit date and the edit history
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.CreationDate AS LastEditDate,
    ARRAY_AGG(ph.Comment) AS EditComments
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId IN (1, 2) -- Questions and Answers
GROUP BY 
    p.Id
HAVING 
    COUNT(ph.Id) > 1
ORDER BY 
    LastEditDate DESC;

-- Summarize users' engagement
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    SUM(COALESCE(b.Class, 0)) AS TotalBadges,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT ph.Id) AS TotalPostEdits
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (2, 3)
LEFT JOIN 
    PostHistory ph ON u.Id = ph.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalBadges DESC
LIMIT 20;
