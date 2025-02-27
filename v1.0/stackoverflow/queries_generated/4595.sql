WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(AVG(vote.Value), 0) AS AverageScore,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 
                     WHEN VoteTypeId = 3 THEN -1 
                     ELSE 0 END) AS Value
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vote ON p.Id = vote.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PopularPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.AverageScore, 
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    WHERE 
        rp.Rank = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.AverageScore
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        ARRAY_AGG(DISTINCT b.Name) AS BadgeNames
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    u.DisplayName,
    COALESCE(pb.CommentCount, 0) AS PopularPostsCommentCount,
    COALESCE(ub.BadgeNames, '{}') AS Badges,
    SUM(pb.AverageScore) AS TotalAverageScore
FROM 
    Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PopularPosts pb ON u.Id = pb.PostId
GROUP BY 
    up.UserId, u.DisplayName
HAVING 
    SUM(pb.AverageScore) > 10 OR COUNT(pb.PostId) > 5
ORDER BY 
    TotalAverageScore DESC NULLS LAST;
