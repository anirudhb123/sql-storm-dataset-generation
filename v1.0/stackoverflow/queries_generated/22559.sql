WITH UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.ViewCount > 100 THEN p.Id END) AS PopularPostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
UserRankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '90 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS IsClosed
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    us.UserId,
    us.Reputation,
    us.TotalBounty,
    us.BadgeCount,
    us.PostCount,
    us.QuestionCount,
    us.PopularPostCount,
    STRING_AGG(DISTINCT p.Title, ', ') FILTER (WHERE us.PostCount > 0) AS RecentPostTitles,
    COUNT(DISTINCT CASE WHEN cp.IsClosed = 1 THEN cp.PostId END) AS ClosedPostCount,
    COALESCE(SUM(CASE WHEN rp.UserPostRank = 1 THEN 1 ELSE 0 END), 0) AS MostRecentPostCount
FROM 
    UserScoreSummary us
LEFT JOIN 
    ClosedPosts cp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
LEFT JOIN 
    UserRankedPosts rp ON us.UserId = rp.UserPostRank 
GROUP BY 
    us.UserId, us.Reputation, us.TotalBounty, us.BadgeCount, us.PostCount, us.QuestionCount, us.PopularPostCount
HAVING 
    us.Reputation > 1000 AND 
    COALESCE(SUM(cp.IsClosed), 0) < 5
ORDER BY 
    us.Reputation DESC NULLS LAST;
