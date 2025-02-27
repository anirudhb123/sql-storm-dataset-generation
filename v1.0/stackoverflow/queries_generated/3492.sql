WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        UpVotes,
        DownVotes,
        RecentRank
    FROM 
        PostStatistics
    WHERE 
        RecentRank <= 10
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
CombinedStatistics AS (
    SELECT 
        ps.Title,
        ps.ViewCount,
        us.DisplayName AS Owner,
        us.PostsCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        TopPosts ps
    JOIN 
        Users u ON ps.PostId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
    JOIN 
        UserStatistics us ON u.Id = us.UserId
)
SELECT 
    *,
    CASE 
        WHEN GoldBadges > 0 THEN 'Gold'
        WHEN SilverBadges > 0 THEN 'Silver'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    CombinedStatistics
WHERE 
    PostId IS NOT NULL
ORDER BY 
    ViewCount DESC, Title ASC;
