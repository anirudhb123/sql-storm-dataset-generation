WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(bp.Reputation) OVER (PARTITION BY u.Id) AS TotalReputation,
        MAX(rp.RecentPostRank) AS RecentPostRank
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ViolationStats AS (
    SELECT 
        u.UserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN p.ClosedDate IS NOT NULL THEN p.Id END) AS ClosedPostCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.UserId
),
FinalReport AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalReputation,
        vs.CommentCount,
        vs.ClosedPostCount,
        CASE 
            WHEN us.RecentPostRank > 10 THEN 'Inactive'
            WHEN us.TotalPosts > 50 THEN 'Active Contributor'
            ELSE 'New Contributor'
        END AS UserActivityStatus
    FROM 
        UserStatistics us
    LEFT JOIN 
        ViolationStats vs ON us.UserId = vs.UserId
)
SELECT 
    fr.*,
    COALESCE(NULLIF(fr.CommentCount, 0), fr.TotalPosts) AS EffectiveEngagement,
    (fr.TotalReputation / NULLIF(fr.TotalPosts, 0)) AS AverageReputationPerPost
FROM 
    FinalReport fr
WHERE 
    fr.TotalReputation IS NOT NULL
ORDER BY 
    fr.TotalReputation DESC, fr.TotalPosts DESC
LIMIT 100;
