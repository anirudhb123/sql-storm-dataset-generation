
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        COALESCE(p.Score, 0) AS Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        UPS.PostId,
        UPS.Score,
        UPS.ViewCount,
        UPS.CommentCount,
        UPS.UpVotes,
        UPS.DownVotes,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics UPS ON u.Id = UPS.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    up.DisplayName,
    up.PostId,
    COALESCE(up.Score, -1) AS Score,
    COALESCE(up.ViewCount, -1) AS ViewCount,
    CASE 
        WHEN up.CommentCount > 0 THEN CONCAT('Comments: ', up.CommentCount) 
        ELSE 'No Comments' 
    END AS CommentDetails,
    CONCAT('UpVotes: ', up.UpVotes, ', DownVotes: ', up.DownVotes) AS VoteSummary,
    CASE 
        WHEN up.TotalBadges > 0 THEN CONCAT('Badges: ', up.TotalBadges) 
        ELSE 'No Badges' 
    END AS BadgeSummary,
    GROUP_CONCAT(DISTINCT tag.TagName SEPARATOR ', ') AS Tags
FROM 
    UserPostStats up
LEFT JOIN 
    Posts p ON up.PostId = p.Id
LEFT JOIN (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
    FROM 
        Posts p
    INNER JOIN (
        SELECT 
            a.N + b.N * 10 + 1 n
        FROM 
            (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
             UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
             UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
             UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
             UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n
    WHERE 
        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
) AS tag ON TRUE
GROUP BY 
    up.DisplayName, up.PostId, up.Score, up.ViewCount, up.CommentCount, up.UpVotes, up.DownVotes, up.TotalBadges
HAVING 
    COALESCE(up.UpVotes, 0) - COALESCE(up.DownVotes, 0) > 0
ORDER BY 
    up.Score DESC, up.DisplayName ASC
LIMIT 100;
