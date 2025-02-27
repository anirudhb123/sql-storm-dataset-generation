WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
BadgesCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Only Gold Badges
    GROUP BY 
        b.UserId
)
SELECT 
    ud.UserId,
    ud.DisplayName,
    COALESCE(bc.BadgeCount, 0) AS GoldBadgeCount,
    COUNT(rp.Id) AS QuestionCount,
    SUM(rp.ViewCount) AS TotalViews,
    AVG(rp.Score) AS AverageScore,
    SUM(ud.Upvotes - ud.Downvotes) AS NetVotes
FROM 
    UserDetails ud
LEFT JOIN 
    RankedPosts rp ON ud.UserId = rp.OwnerUserId
LEFT JOIN 
    BadgesCount bc ON ud.UserId = bc.UserId
GROUP BY 
    ud.UserId, ud.DisplayName, bc.BadgeCount
HAVING 
    COUNT(rp.Id) > 0 
    AND SUM(rp.ViewCount) > 100 
ORDER BY 
    NetVotes DESC, TotalViews DESC
LIMIT 10;
