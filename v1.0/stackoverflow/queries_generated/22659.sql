WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        COUNT(DISTINCT CASE WHEN b.UserId IS NOT NULL THEN b.Id END) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
        LEFT JOIN STRING_TO_ARRAY(p.Tags, ',') AS t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        MAX(u.Reputation) AS MaxReputation,
        MAX(u.Views) AS MaxViews,
        CASE 
            WHEN MAX(u.Reputation) IS NULL THEN 'Newcomer'
            WHEN MAX(u.Reputation) < 100 THEN 'Beginner'
            WHEN MAX(u.Reputation) < 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS UserLevel
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.UserLevel,
    rp.Title,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.BadgeCount,
    rp.Tags,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score >= 10 THEN 'Highly Favorable'
        WHEN rp.Score BETWEEN 1 AND 9 THEN 'Moderate'
        ELSE 'Needs Improvement'
    END AS PostQuality,
    COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END), 0) AS IsClosedPost
FROM 
    UserStats us
    JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId
    LEFT JOIN PostHistory ph ON rp.Id = ph.PostId
GROUP BY 
    us.DisplayName, us.UserLevel, rp.Title, rp.CommentCount, 
    rp.UpVoteCount, rp.DownVoteCount, rp.BadgeCount, rp.Tags,
    rp.Score
HAVING 
    us.TotalPosts > 10 
    AND MAX(rp.Score) > 0
ORDER BY 
    us.MaxReputation DESC, 
    rp.Score DESC, 
    us.DisplayName ASC;
