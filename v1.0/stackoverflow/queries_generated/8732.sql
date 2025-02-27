WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersGiven,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserTagActivity AS (
    SELECT 
        ur.UserId,
        ut.TagName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS Comments
    FROM 
        UserReputation ur
    CROSS JOIN 
        PopularTags ut
    LEFT JOIN 
        Posts p ON p.OwnerUserId = ur.UserId AND p.Tags LIKE '%' || ut.TagName || '%'
    LEFT JOIN 
        Comments c ON c.UserId = ur.UserId AND p.Id = c.PostId
    GROUP BY 
        ur.UserId, ut.TagName
)
SELECT 
    u.DisplayName,
    u.Reputation,
    t.TagName,
    ta.Questions,
    ta.Answers,
    ta.Comments
FROM 
    UserReputation u
JOIN 
    UserTagActivity ta ON u.UserId = ta.UserId
JOIN 
    PopularTags t ON ta.TagName = t.TagName
ORDER BY 
    u.Reputation DESC, t.PostCount DESC;
