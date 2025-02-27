WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.CommentCount,
        r.UpVoteCount,
        r.DownVoteCount,
        COALESCE(u.DisplayName, 'Deleted User') AS AuthorDisplayName,
        ua.PostCount AS UserPostCount,
        ua.TotalScore AS UserTotalScore,
        ua.BadgeCount AS UserBadgeCount 
    FROM 
        RecentPosts r
    LEFT JOIN 
        Users u ON r.OwnerUserId = u.Id
    LEFT JOIN 
        UserActivity ua ON u.Id = ua.UserId
)

SELECT 
    p.Title,
    p.CreationDate,
    p.Score AS PostScore,
    p.ViewCount,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.AuthorDisplayName,
    p.UserPostCount,
    p.UserTotalScore,
    p.UserBadgeCount,
    CASE 
        WHEN p.CommentCount > 0 THEN 'Comments Available'
        ELSE 'No Comments Yet'
    END AS CommentStatus,
    CASE 
        WHEN p.UpVoteCount > p.DownVoteCount THEN 'Positive Engagement'
        ELSE 'Mixed or Negative Engagement'
    END AS EngagementLevel
FROM 
    PostStatistics p
WHERE 
    p.Score >= 10
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 50;
