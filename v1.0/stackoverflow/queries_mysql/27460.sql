
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        CONCAT(Users.DisplayName, ' (Reputation: ', Users.Reputation, ')') AS UserDisplayName,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.DisplayName, Users.Reputation
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        @rank := IF(@prev = PostCount, @rank, @rank + 1) AS TagRank,
        @prev := PostCount
    FROM 
        TagCounts, (SELECT @rank := 0, @prev := NULL) r
    ORDER BY 
        PostCount DESC
),
ActiveUsers AS (
    SELECT 
        UserReputation.UserId,
        UserReputation.UserDisplayName,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT Posts.Id) AS QuestionCount
    FROM 
        UserReputation
    JOIN 
        Votes ON UserReputation.UserId = Votes.UserId
    JOIN 
        Posts ON Votes.PostId = Posts.Id
    GROUP BY 
        UserReputation.UserId, UserReputation.UserDisplayName
    HAVING 
        COUNT(DISTINCT Posts.Id) > 0
)
SELECT 
    t.Tag,
    t.PostCount,
    u.UserDisplayName,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.QuestionCount
FROM 
    TopTags t
JOIN 
    ActiveUsers u ON u.QuestionCount > 0
WHERE 
    t.TagRank <= 10  
ORDER BY 
    t.PostCount DESC, u.TotalUpVotes DESC;
