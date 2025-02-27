WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVoteCount  -- Upvotes
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
    WHERE u.Reputation > 1000 -- Only consider users with reputation greater than 1000
    GROUP BY u.Id
),
TopTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagUsage
    FROM PostTags
    GROUP BY Tag
    ORDER BY TagUsage DESC
    LIMIT 10
),
UserUpvotes AS (
    SELECT 
        au.DisplayName,
        tt.Tag,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes
    FROM ActiveUsers au
    JOIN Posts p ON au.UserId = p.OwnerUserId
    JOIN PostTags pt ON p.Id = pt.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE pt.Tag IN (SELECT Tag FROM TopTags)
    GROUP BY au.DisplayName, tt.Tag
)
SELECT 
    u.DisplayName,
    tt.Tag,
    uu.TotalUpvotes,
    COUNT(DISTINCT p.Id) AS QuestionsAnswered,
    AVG(u.Reputation) AS AverageReputation,
    MAX(p.CreationDate) AS LastPostDate
FROM UserUpvotes uu
JOIN ActiveUsers u ON uu.DisplayName = u.DisplayName
JOIN PostTags pt ON uu.Tag = pt.Tag
JOIN Posts p ON pt.PostId = p.Id
GROUP BY u.DisplayName, tt.Tag
ORDER BY TotalUpvotes DESC, AverageReputation DESC;
This SQL query benchmarks string processing by analyzing tags associated with questions and correlating them with user activity. It identifies active users who have a significant number of questions and correlates their upvote counts with the top ten most used tags, providing insights into both user engagement and tag utilization.
