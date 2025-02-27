WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AcceptedAnswers,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.AcceptedAnswerId IS NOT NULL  -- Accepted Answers
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),

TopTags AS (
    SELECT 
        t.TagName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL AND p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')  -- Filter by tags
    GROUP BY 
        t.Id, t.TagName
    HAVING 
        COUNT(p.Id) > 10  -- Only consider tags with more than 10 posts
),

UserEngagement AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AcceptedAnswers,
        ua.UpVotes,
        ua.DownVotes,
        tt.TagName,
        RANK() OVER (PARTITION BY ua.UserId ORDER BY ua.UpVotes DESC) AS PopularityRank
    FROM 
        UserActivity ua
    JOIN 
        TopTags tt ON tt.QuestionCount > 5  -- Only engage users who have significant tag activity
)

SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.QuestionCount,
    ue.AcceptedAnswers,
    ue.UpVotes,
    ue.DownVotes,
    STRING_AGG(DISTINCT ue.TagName, ', ') AS TagsEngaged,
    RANK() OVER (ORDER BY ue.UpVotes DESC) AS OverallRanking
FROM 
    UserEngagement ue
GROUP BY 
    ue.UserId, ue.DisplayName, ue.QuestionCount, ue.AcceptedAnswers, ue.UpVotes, ue.DownVotes
ORDER BY 
    OverallRanking
LIMIT 10;
