WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
), FilteredPosts AS (
    SELECT 
        rp.*,
        COALESCE(up.UserId, -1) AS UpVotedUserId,
        COALESCE(dp.UserId, -1) AS DownVotedUserId,
        CASE 
            WHEN rp.Score > 10 THEN 'High Scoring'
            WHEN rp.Score BETWEEN 5 AND 10 THEN 'Moderate Scoring'
            ELSE 'Low Scoring'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes up ON rp.PostId = up.PostId AND up.VoteTypeId = 2
    LEFT JOIN 
        Votes dp ON rp.PostId = dp.PostId AND dp.VoteTypeId = 3
), MostActiveUsers AS (
    SELECT 
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.DisplayName
    HAVING 
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) > 5
), UserBadges AS (
    SELECT 
        b.UserId, 
        STRING_AGG(b.Name, ', ') AS BadgeList,
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    f.Title,
    f.CreationDate,
    f.ScoreCategory,
    f.CommentCount,
    COALESCE(ub.BadgeList, 'No badges') AS UserBadges,
    mau.PostCount AS TotalPostsByUser,
    mau.CommentCount AS TotalCommentsByUser
FROM 
    FilteredPosts f
LEFT JOIN 
    MostActiveUsers mau ON f.UpVotedUserId = mau.UserId OR f.DownVotedUserId = mau.UserId
LEFT JOIN 
    UserBadges ub ON f.UpVotedUserId = ub.UserId OR f.DownVotedUserId = ub.UserId
WHERE 
    f.RankByUser <= 5
ORDER BY 
    f.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
