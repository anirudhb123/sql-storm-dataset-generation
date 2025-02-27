WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
),
PostStats AS (
    SELECT 
        PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts ps
    LEFT JOIN 
        Comments c ON c.PostId = ps.Id
    LEFT JOIN 
        Votes v ON v.PostId = ps.Id 
    GROUP BY 
        PostId
),
Utility AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        ps.CommentCount,
        ps.TotalBounty,
        CASE 
            WHEN ps.TotalBounty IS NULL THEN 'No Bounty'
            WHEN ps.TotalBounty > 0 THEN 'Bounty Available'
            ELSE 'Bounty Used'
        END AS BountyStatus
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostStats ps ON r.PostId = ps.PostId
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COALESCE(u.Views, 0) AS TotalViews,
    u.Reputation AS UserReputation,
    u.CreationDate AS UserCreationDate,
    u.LastAccessDate AS UserLastAccessDate,
    u.EmailHash,
    MAX(CASE WHEN u.Views IS NOT NULL THEN u.Views ELSE 0 END) OVER (PARTITION BY pos.PostId) AS MaxViewCount,
    CONCAT(u.DisplayName, ' has ', COALESCE(ps.CommentCount, 0), ' comments on post: ', util.Title) AS CommentSummary,
    util.BountyStatus,
    util.CreationDate AS PostCreationDate
FROM 
    Users u
JOIN 
    Utility util ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = util.PostId)
LEFT JOIN 
    Posts pos ON pos.Id = util.PostId
WHERE 
    util.Rank = 1
AND 
    (u.Reputation IS NOT NULL OR u.Reputation < 1000)
ORDER BY 
    UserReputation DESC, util.PostCreationDate DESC
LIMIT 100;
