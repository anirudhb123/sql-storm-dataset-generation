WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersProvided,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        MAX(u.CreationDate) AS UserRegistrationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(Tags, '><'))
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
ActiveAuthors AS (
    SELECT 
        ua.DisplayName,
        ua.QuestionsAsked,
        ua.AnswersProvided,
        pt.Name AS PostType
    FROM 
        UserActivity ua
    JOIN 
        Posts p ON ua.UserId = p.OwnerUserId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        ua.QuestionsAsked > 0 OR ua.AnswersProvided > 0
)
SELECT 
    a.DisplayName,
    a.QuestionsAsked,
    a.AnswersProvided,
    COUNT(p.Id) AS TotalPosts,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    (SELECT STRING_AGG(Tag, ', ') FROM PopularTags) AS PopularTags
FROM 
    ActiveAuthors a
LEFT JOIN 
    Posts p ON a.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    a.DisplayName, a.QuestionsAsked, a.AnswersProvided
ORDER BY 
    a.AnswersProvided DESC
LIMIT 20;
