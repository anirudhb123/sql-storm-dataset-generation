WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
), UserTags AS (
    SELECT 
        p.OwnerUserId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '<>')))
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.QuestionsCount,
    ua.AnswersCount,
    ua.UpVotes,
    ua.DownVotes,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    ut.TagList
FROM 
    UserActivity ua
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN 
    UserTags ut ON ua.UserId = ut.OwnerUserId
ORDER BY 
    ua.TotalPosts DESC, ua.UpVotes DESC
LIMIT 100;
