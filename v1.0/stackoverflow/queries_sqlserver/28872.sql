
WITH TagCounts AS (
    SELECT 
        Posts.Id AS PostId,
        value AS Tag
    FROM 
        Posts
    CROSS APPLY (
        SELECT value 
        FROM STRING_SPLIT(SUBSTRING(Posts.Tags, 2, LEN(Posts.Tags) - 2), '><')
    ) AS SplitTags
    WHERE 
        Posts.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        TagCounts.Tag,
        COUNT(DISTINCT TagCounts.PostId) AS PostCount,
        COUNT(DISTINCT Votes.UserId) AS UniqueVoteCounts,
        STRING_AGG(DISTINCT Users.DisplayName, ',') AS VotedUsers,
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
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, UniqueVoteCounts DESC, AverageScore DESC) AS Rank
    FROM 
        TagStatistics
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
