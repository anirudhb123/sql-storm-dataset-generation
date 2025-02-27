WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
UserScores AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
TagStatistics AS (
    SELECT 
        tc.Tag,
        COUNT(DISTINCT tc.PostId) AS PostCount,
        COUNT(DISTINCT u.Id) AS UserCount,
        AVG(us.TotalScore) AS AverageUserScore
    FROM 
        TagCounts tc
    JOIN 
        Posts p ON tc.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserScores us ON u.Id = us.OwnerUserId
    GROUP BY 
        tc.Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        UserCount,
        AverageUserScore,
        RANK() OVER (ORDER BY PostCount DESC, AverageUserScore DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    Tag, 
    PostCount, 
    UserCount,
    AverageUserScore
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
