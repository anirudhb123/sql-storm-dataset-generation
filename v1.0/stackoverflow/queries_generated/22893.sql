WITH UserTags AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(t.Id) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT DISTINCT UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName, p.Id
        FROM Posts p 
        WHERE p.PostTypeId = 1  -- Questions only
    ) t ON p.Id = t.Id
    GROUP BY u.Id, u.DisplayName
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ut.TagCount, 0) AS TagCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ut.Tags, 'No tags') AS UserTags,
        COALESCE(ub.BadgeNames, 'No badges') AS UserBadges,
        u.Reputation,
        u.CreationDate
    FROM Users u
    LEFT JOIN UserTags ut ON u.Id = ut.UserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
),

ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TagCount,
        ua.BadgeCount,
        ua.Reputation,
        DENSE_RANK() OVER (ORDER BY ua.Reputation DESC) AS Rank
    FROM UserActivity ua
    WHERE ua.Reputation > 100 -- Filter users with reputation > 100
),

QuestionDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentsCount, 0) AS CommentsCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentsCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(Id) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2 -- Answers only
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 -- Questions only
)

SELECT 
    au.DisplayName,
    au.Rank, 
    qd.Title,
    qd.CreationDate,
    qd.Score,
    qd.CommentsCount,
    qd.AnswerCount,
    qd.VoteCount,
    au.TagCount,
    au.BadgeCount,
    au.UserTags,
    au.UserBadges
FROM ActiveUsers au
JOIN QuestionDetails qd ON au.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = qd.PostId)
WHERE au.Rank <= 10  -- Top 10 users based on reputation
ORDER BY au.Rank, qd.Score DESC;
