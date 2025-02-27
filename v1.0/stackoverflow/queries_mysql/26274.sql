
WITH TagFrequency AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS Frequency
    FROM
        Posts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10  -- Extend as needed based on maximum number of tags
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1  
    GROUP BY
        Tag
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        SUM(CASE WHEN v.VoteTypeId IN (6, 7) THEN 1 ELSE 0 END) AS VotesForCloseReopen
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT
        Tag,
        Frequency,
        @rownum := @rownum + 1 AS Rank
    FROM
        TagFrequency, (SELECT @rownum := 0) r
    ORDER BY
        Frequency DESC
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionsAsked,
        UpVotesReceived,
        DownVotesReceived,
        VotesForCloseReopen,
        @userRank := @userRank + 1 AS UserRank
    FROM
        UserEngagement, (SELECT @userRank := 0) r
    ORDER BY
        QuestionsAsked DESC
)
SELECT
    tu.DisplayName AS TopUser,
    tu.QuestionsAsked,
    tu.UpVotesReceived,
    tu.DownVotesReceived,
    tt.Tag AS PopularTag,
    tt.Frequency AS TagFrequency
FROM
    TopUsers tu
JOIN
    TopTags tt ON tu.UserRank <= 10 AND tt.Rank <= 10
ORDER BY
    tu.QuestionsAsked DESC, tt.Frequency DESC;
