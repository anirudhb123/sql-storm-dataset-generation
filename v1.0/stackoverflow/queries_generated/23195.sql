WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(h.HistoryCount, 0) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) b ON p.OwnerUserId = b.UserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS HistoryCount
        FROM PostHistory
        GROUP BY PostId
    ) h ON p.Id = h.PostId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.AnswerCount,
    COUNT(DISTINCT pm.PostId) AS TotalPosts,
    SUM(pm.Score) AS TotalScore,
    SUM(pm.CommentCount) AS TotalComments,
    SUM(pm.BadgeCount) AS TotalBadges,
    MAX(pm.HistoryCount) AS MaxHistoryCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    MAX(us.UserRank) AS UserRank
FROM 
    UserStatistics us
LEFT JOIN 
    PostMetrics pm ON us.UserId = pm.OwnerUserId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(pm.Tags, '<>')) AS TagName
    ) t ON TRUE
WHERE 
    us.CreationDate <= CURRENT_TIMESTAMP - INTERVAL '1 year'
    AND us.Reputation > (SELECT AVG(Reputation) FROM Users)
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.QuestionCount, us.AnswerCount
HAVING 
    COUNT(DISTINCT pm.PostId) > 5
ORDER BY 
    us.Reputation DESC, us.DisplayName ASC
FETCH FIRST 10 ROWS ONLY
OPTION (RECOMPILE);
