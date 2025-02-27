
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', numbers.n), '<>', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '<>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.CommentCount,
        ua.UpVotes,
        ua.DownVotes,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        ub.BadgeNames,
        @rank := IF(@prev_score = (ua.UpVotes - ua.DownVotes), @rank, @rank + 1) AS Rank,
        @prev_score := (ua.UpVotes - ua.DownVotes)
    FROM 
        UserActivity ua
    LEFT JOIN 
        UserBadges ub ON ua.UserId = ub.UserId
    CROSS JOIN 
        (SELECT @rank := 0, @prev_score := NULL) r
    ORDER BY 
        ua.UpVotes - ua.DownVotes DESC
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.CommentCount,
    ru.UpVotes,
    ru.DownVotes,
    ru.BadgeCount,
    ru.BadgeNames,
    pt.TagName,
    pt.TagCount
FROM 
    RankedUsers ru
CROSS JOIN 
    PopularTags pt
WHERE 
    ru.Rank <= 10  
    AND ru.CommentCount > 5  
ORDER BY 
    (ru.UpVotes - ru.DownVotes) DESC, 
    pt.TagCount DESC;
