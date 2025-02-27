
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
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
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
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
        WHEN up.CommentCount > 0 THEN 'Comments: ' + CAST(up.CommentCount AS VARCHAR) 
        ELSE 'No Comments' 
    END AS CommentDetails,
    'UpVotes: ' + CAST(up.UpVotes AS VARCHAR) + ', DownVotes: ' + CAST(up.DownVotes AS VARCHAR) AS VoteSummary,
    CASE 
        WHEN up.TotalBadges > 0 THEN 'Badges: ' + CAST(up.TotalBadges AS VARCHAR) 
        ELSE 'No Badges' 
    END AS BadgeSummary,
    STRING_AGG(DISTINCT tag.TagName, ', ') AS Tags
FROM 
    UserPostStats up
LEFT JOIN 
    Posts p ON up.PostId = p.Id
OUTER APPLY (
    SELECT 
        value AS TagName 
    FROM 
        STRING_SPLIT(p.Tags, '><')
) AS tag
GROUP BY 
    up.DisplayName, up.PostId, up.Score, up.ViewCount, up.CommentCount, up.UpVotes, up.DownVotes, up.TotalBadges
HAVING 
    COALESCE(up.UpVotes, 0) - COALESCE(up.DownVotes, 0) > 0
ORDER BY 
    up.Score DESC, up.DisplayName ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
