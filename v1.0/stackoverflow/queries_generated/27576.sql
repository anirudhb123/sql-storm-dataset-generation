WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COALESCE(MAX(p.CreationDate), '1970-01-01') AS LatestPostDate -- Default to a past date if no posts exist
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t ON TRUE
    GROUP BY 
        u.Id, u.DisplayName
),
AggregateActivities AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVoteCount,
        DownVoteCount,
        BadgeCount,
        Tags,
        LatestPostDate,
        RANK() OVER (ORDER BY UpVoteCount DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank
    FROM 
        UserActivity
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount,
    QuestionCount,
    AnswerCount,
    UpVoteCount,
    DownVoteCount,
    BadgeCount,
    Tags,
    LatestPostDate,
    UpVoteRank,
    QuestionRank,
    CASE 
        WHEN UpVoteCount > AnswerCount THEN 'Popular Answerer'
        WHEN QuestionCount > AnswerCount THEN 'Active Questioner'
        ELSE 'General User'
    END AS UserCategory
FROM 
    AggregateActivities
WHERE 
    PostCount > 0
ORDER BY 
    UpVoteCount DESC, 
    QuestionCount DESC;
