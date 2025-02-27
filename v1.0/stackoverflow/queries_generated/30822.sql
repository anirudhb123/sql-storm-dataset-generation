WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Reputation < ur.Reputation
    WHERE 
        ur.Level < 5
),
RecentQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        p.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerDisplayName, p.Score
    HAVING 
        p.CreationDate > NOW() - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    rq.PostId,
    rq.Title AS QuestionTitle,
    rq.CreationDate AS QuestionDate,
    rq.CommentCount,
    tt.TagName,
    tt.PostCount
FROM 
    Users u
JOIN 
    UserReputation ur ON u.Id = ur.Id
LEFT JOIN 
    RecentQuestions rq ON u.Id = rq.OwnerUserId
JOIN 
    TopTags tt ON tt.PostCount > 0
WHERE 
    u.Location IS NOT NULL
    AND u.CreationDate <= NOW() - INTERVAL '1 year'
ORDER BY 
    ur.Reputation DESC, rq.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

WITH UserActivity AS (
    SELECT 
        UserId,
        COUNT(PostId) AS QuestionCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        UserId
)

SELECT 
    ua.UserId,
    ua.QuestionCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.AcceptedAnswers,
    up.DisplayName
FROM 
    UserActivity ua
JOIN 
    Users up ON ua.UserId = up.Id
ORDER BY 
    ua.QuestionCount DESC, ua.UpVotes - ua.DownVotes DESC;

-- Combine results for detailed reporting
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.QuestionCount,
    u.UpVotes,
    u.DownVotes,
    COALESCE(rt.TagName, 'No Tags') AS TopTag,
    COALESCE(rt.PostCount, 0) AS TopTagPostCount
FROM 
    (SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ua.QuestionCount, 0) AS QuestionCount,
        COALESCE(ua.UpVotes, 0) AS UpVotes,
        COALESCE(ua.DownVotes, 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        UserActivity ua ON u.Id = ua.UserId
    WHERE 
        u.Reputation > 100
    ) AS u
LEFT JOIN
    (SELECT 
        tt.TagName,
        tt.PostCount,
        COUNT(q.PostId) AS QuestionCount
    FROM 
        TopTags tt
    JOIN 
        RecentQuestions q ON tt.PostCount > 0
    GROUP BY 
        tt.TagName, tt.PostCount
    ) AS rt ON u.QuestionCount = rt.QuestionCount
ORDER BY 
    u.Reputation DESC;
