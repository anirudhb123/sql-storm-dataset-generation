
WITH TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag, 
        COUNT(DISTINCT Id) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount, 
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
EngagedUsers AS (
    SELECT 
        ue.UserId, 
        ue.DisplayName,
        ue.QuestionCount,
        ue.UpVotesReceived,
        ue.DownVotesReceived,
        (ue.UpVotesReceived - ue.DownVotesReceived) AS NetVotes
    FROM 
        UserEngagement ue
    WHERE 
        ue.QuestionCount > 0
),
UserTagInteraction AS (
    SELECT 
        u.Id AS UserId,
        t.Tag,
        COUNT(DISTINCT p.Id) AS TaggedPostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        TagStatistics t ON t.Tag IN (SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1))
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, t.Tag
),
OverallStats AS (
    SELECT 
        ue.DisplayName,
        COALESCE(SUM(uti.TaggedPostCount), 0) AS TotalTaggedPosts,
        COALESCE(SUM(ue.QuestionCount), 0) AS TotalQuestions,
        COALESCE(SUM(ue.NetVotes), 0) AS TotalNetVotes
    FROM 
        EngagedUsers ue
    LEFT JOIN 
        UserTagInteraction uti ON ue.UserId = uti.UserId
    GROUP BY 
        ue.DisplayName
)
SELECT 
    ots.DisplayName,
    ots.TotalTaggedPosts,
    ots.TotalQuestions,
    ots.TotalNetVotes,
    tt.Tag,
    tt.PostCount
FROM 
    OverallStats ots
JOIN 
    TopTags tt ON ots.TotalTaggedPosts > 0
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    ots.TotalQuestions DESC, ots.TotalNetVotes DESC;
