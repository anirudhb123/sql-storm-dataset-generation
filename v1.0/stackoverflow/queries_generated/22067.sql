WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,  -- Upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount  -- Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN bp.PostRank = 1 THEN bp.Score END), 0) AS TopScore,  -- Top scoring post
        COALESCE(AVG(bp.Score), 0) AS AvgScore,  -- Average score
        COUNT(DISTINCT b.Id) AS BadgeCount  -- Count of badges
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts bp ON u.Id = bp.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TopScore,
        us.AvgScore,
        us.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY us.TopScore DESC, us.AvgScore DESC, us.BadgeCount DESC) AS UserRank
    FROM 
        UserScore us
    WHERE 
        us.TopScore > 0 AND us.BadgeCount > 0  -- Filtering to have only users with top scores and badges
)
SELECT 
    fu.UserId,
    fu.DisplayName,
    fu.TopScore,
    fu.AvgScore,
    fu.BadgeCount,
    CASE 
        WHEN fu.BadgeCount > 5 THEN 'Expert'
        WHEN fu.BadgeCount BETWEEN 3 AND 5 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    COALESCE(MAX(ph.CreationDate), 'No history available') AS LastPostHistoryDate
FROM 
    FilteredUsers fu
LEFT JOIN 
    PostHistory ph ON fu.UserId = ph.UserId
WHERE 
    fu.UserRank <= 10  -- Top 10 users with the highest scores
GROUP BY 
    fu.UserId, fu.DisplayName, fu.TopScore, fu.AvgScore, fu.BadgeCount
ORDER BY 
    fu.TopScore DESC, fu.AvgScore DESC;
