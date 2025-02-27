WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS TotalUpVotes,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS TotalDownVotes
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Tags.TagName
),
UserReputation AS (
    SELECT 
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS QuestionCount,
        SUM(Posts.Score) AS TotalScore,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS DownVotes
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId 
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId 
    WHERE 
        Posts.PostTypeId = 1 -- Only questions
    GROUP BY 
        Users.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalUpVotes - TotalDownVotes AS NetVotes
    FROM 
        TagStatistics
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
UserScores AS (
    SELECT 
        ur.DisplayName,
        ur.QuestionCount,
        ur.TotalScore,
        ur.UpVotes - ur.DownVotes AS NetVotes
    FROM 
        UserReputation ur
    JOIN 
        TopTags tt ON tt.PostCount > 0
)
SELECT 
    tt.TagName,
    us.DisplayName,
    us.QuestionCount,
    us.TotalScore,
    us.NetVotes
FROM 
    TopTags tt
JOIN 
    UserScores us ON us.QuestionCount > 0
ORDER BY 
    tt.NetVotes DESC, 
    us.TotalScore DESC;
