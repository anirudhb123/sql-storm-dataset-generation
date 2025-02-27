
WITH TagCounts AS (
    SELECT 
        Posts.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Posts.Tags) - CHAR_LENGTH(REPLACE(Posts.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        Posts.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        TagCounts.Tag,
        COUNT(DISTINCT TagCounts.PostId) AS PostCount,
        COUNT(DISTINCT Votes.UserId) AS UniqueVoteCounts,
        GROUP_CONCAT(DISTINCT Users.DisplayName) AS VotedUsers,
        AVG(Posts.Score) AS AverageScore,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.AnswerCount) AS TotalAnswers
    FROM 
        TagCounts
    LEFT JOIN 
        Posts ON TagCounts.PostId = Posts.Id
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId AND Votes.VoteTypeId = 2  
    LEFT JOIN 
        Users ON Votes.UserId = Users.Id
    GROUP BY 
        TagCounts.Tag
),
RankedTags AS (
    SELECT 
        Tag,
        PostCount,
        UniqueVoteCounts,
        VotedUsers,
        AverageScore,
        TotalViews,
        TotalAnswers,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC, UniqueVoteCounts DESC, AverageScore DESC
)

SELECT 
    Tag,
    PostCount,
    UniqueVoteCounts,
    VotedUsers,
    AverageScore,
    TotalViews,
    TotalAnswers,
    Rank
FROM 
    RankedTags
WHERE 
    Rank <= 10  
ORDER BY 
    Rank;
