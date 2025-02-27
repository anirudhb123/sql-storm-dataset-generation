WITH UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS t(TagName) ON t.TagName IS NOT NULL
    WHERE 
        u.Reputation > 5000
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS HistoryComments
    FROM 
        Posts p
        LEFT JOIN (
            SELECT 
                PostId, 
                COUNT(*) AS CommentCount 
            FROM 
                Comments 
            GROUP BY 
                PostId
        ) c ON p.Id = c.PostId
        LEFT JOIN (
            SELECT 
                ParentId, 
                COUNT(*) AS AnswerCount 
            FROM 
                Posts 
            WHERE 
                PostTypeId = 2 
            GROUP BY 
                ParentId
        ) a ON p.Id = a.ParentId
        LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
UserPostStats AS (
    SELECT 
        ud.UserId,
        ud.DisplayName,
        ud.Reputation,
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.CommentCount,
        ps.AnswerCount,
        ps.HistoryComments
    FROM 
        UserDetails ud
        JOIN Posts p ON ud.UserId = p.OwnerUserId
        JOIN PostStats ps ON p.Id = ps.PostId
)
SELECT 
    ups.DisplayName,
    ups.Reputation,
    ups.Title AS PostTitle,
    ups.CreationDate,
    ups.Score,
    ups.CommentCount,
    ups.AnswerCount,
    ups.HistoryComments,
    ups.AssociatedTags
FROM 
    UserPostStats ups
ORDER BY 
    ups.Reputation DESC, ups.Score DESC
LIMIT 10;
