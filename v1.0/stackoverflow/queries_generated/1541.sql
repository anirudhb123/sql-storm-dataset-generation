WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score >= 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(b.BadgeNames, 'No badges') AS Badges,
    COALESCE(bp.PostCount, 0) AS TotalPosts,
    COALESCE(rp.UserPostRank, 0) AS LatestPostRank,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    COALESCE(rp.UpVoteCount, 0) - COALESCE(rp.DownVoteCount, 0) AS NetVotes
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON b.UserId = u.Id
LEFT JOIN 
    (SELECT 
        OwnerUserId,
        COUNT(Id) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId) bp ON bp.OwnerUserId = u.Id
LEFT JOIN 
    RankedPosts rp ON rp.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = u.Id ORDER BY CreationDate DESC LIMIT 1)
WHERE 
    u.Reputation >= 1000
ORDER BY 
    u.Reputation DESC, LatestPostRank ASC;
