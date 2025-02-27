WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.Tags,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,  -- Count of upvotes
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes,  -- Count of downvotes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS GlobalRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year') 
        AND p.PostTypeId = 1  -- Only Questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserDetails AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        CASE 
            WHEN u.LastAccessDate < (CURRENT_TIMESTAMP - INTERVAL '6 months') THEN 'Inactive'
            ELSE 'Active'
        END AS Status
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ud.DisplayName,
    ud.Reputation,
    ud.BadgeCount,
    rp.UpVotes,
    rp.DownVotes,
    ud.Status AS UserStatus,
    rp.GlobalRank,
    CASE 
        WHEN rp.GlobalRank <= 10 THEN 'Top 10% of Posts'
        ELSE 'Below Top 10%'
    END AS PostRanking
FROM 
    RankedPosts rp
JOIN 
    UserDetails ud ON rp.OwnerUserId = ud.Id
WHERE 
    rp.UserRank <= 5 -- Top 5 posts for each user
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
