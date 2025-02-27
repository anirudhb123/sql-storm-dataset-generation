WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount > 500
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
    HAVING 
        MAX(b.Date) >= NOW() - INTERVAL '6 months'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COALESCE(SUM(vote.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(vote.VoteTypeId = 3), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes vote ON u.Id = vote.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    r.Title,
    r.ViewCount,
    r.Score,
    r.AnswerCount,
    r.CreationDate,
    be.BadgeCount,
    SUM(ue.TotalBounty) AS TotalBountyEarned,
    (ue.TotalUpVotes - ue.TotalDownVotes) AS NetVotes
FROM 
    Users u
JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId
LEFT JOIN 
    RecentBadges be ON u.Id = be.UserId
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    r.UserPostRank <= 5
GROUP BY 
    u.DisplayName, u.Reputation, r.Title, r.ViewCount, 
    r.Score, r.AnswerCount, r.CreationDate, be.BadgeCount
ORDER BY 
    NetVotes DESC, u.Reputation DESC
LIMIT 10;
