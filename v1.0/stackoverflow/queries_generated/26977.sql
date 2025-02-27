WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only considering Questions
), 
TagUsage AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Only Questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
TopTags AS (
    SELECT 
        tag.Tag,
        tag.QuestionCount
    FROM 
        TagUsage tag
    ORDER BY 
        tag.QuestionCount DESC
    LIMIT 10  -- Get the top 10 tags
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.QuestionsAsked,
    u.UpvotesReceived,
    t.Tag
FROM 
    UserReputation u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId AND p.PostTypeId = 1  -- Only Questions
JOIN 
    TopTags t ON t.Tag = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) -- Join to get relevant tags
GROUP BY 
    u.DisplayName, u.Reputation, u.QuestionsAsked, u.UpvotesReceived, t.Tag
ORDER BY 
    u.Reputation DESC, t.QuestionCount DESC; -- Order by Reputation and Tag usage
