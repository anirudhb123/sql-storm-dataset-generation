WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        r.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostDetails AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.CreationDate,
        ph.ViewCount,
        ph.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(b.BadgeNames, 'None') AS UserBadgeNames,
        u.Reputation,
        u.DisplayName
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        PostVoteSummary v ON ph.PostId = v.PostId
    LEFT JOIN 
        Users u ON ph.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.TotalVotes,
    pd.UserBadgeCount,
    pd.UserBadgeNames,
    pd.Reputation,
    pd.DisplayName,
    CASE 
        WHEN pd.Score >= 10 THEN 'Hot'
        WHEN pd.Score BETWEEN 5 AND 9 THEN 'Trending'
        ELSE 'New'
    END AS Status,
    DENSE_RANK() OVER (ORDER BY pd.Score DESC) AS Rank
FROM 
    PostDetails pd
WHERE 
    pd.ViewCount > 0
ORDER BY 
    pd.Rank;
