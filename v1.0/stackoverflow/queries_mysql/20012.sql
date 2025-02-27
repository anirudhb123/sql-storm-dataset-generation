
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        @row_num := IF(@prev_user = p.OwnerUserId, @row_num + 1, 1) AS Rank,
        @prev_user := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_num := 0, @prev_user := NULL) AS vars
    WHERE 
        p.CreationDate >= '2020-01-01' AND
        p.Title IS NOT NULL AND 
        (p.Tags LIKE '%SQL%' OR p.Tags LIKE '%Database%')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= (CAST('2024-10-01' AS DATE) - INTERVAL 30 DAY)
    GROUP BY 
        b.UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(rb.BadgeNames, 'No recent badges') AS RecentBadges,
        COALESCE(rb.BadgeCount, 0) AS NumberOfBadges,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePosts,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation IS NOT NULL 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, rb.BadgeNames, rb.BadgeCount 
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
FinalReport AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.RecentBadges,
        us.NumberOfBadges,
        @rank := @rank + 1 AS ReputationRank,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.Upvotes) AS TotalUpvotes,
        SUM(rp.Downvotes) AS TotalDownvotes
    FROM 
        UserStats us
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
    CROSS JOIN (SELECT @rank := 0) AS r
    GROUP BY 
        us.UserId, us.DisplayName, us.Reputation, us.RecentBadges, us.NumberOfBadges
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    RecentBadges,
    NumberOfBadges,
    ReputationRank,
    COALESCE(TotalComments, 0) AS CommentSummary,
    COALESCE(TotalUpvotes, 0) AS UpvotesSummary,
    COALESCE(TotalDownvotes, 0) AS DownvotesSummary
FROM 
    FinalReport
WHERE 
    NumberOfBadges > 0
ORDER BY 
    ReputationRank;
