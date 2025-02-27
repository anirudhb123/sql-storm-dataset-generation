WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- only considering questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
),
RecentUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- only considering questions
        AND p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        u.DisplayName
),
ActiveUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(c.Id) AS CommentsMade,
        SUM(v.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Comments c ON u.Id = c.UserId
    JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.DisplayName
),
FinalBenchmark AS (
    SELECT 
        r.TagName,
        t.PostCount AS QuestionsCount,
        u.DisplayName AS ActiveUser,
        u.CommentsMade,
        u.TotalScore,
        r.Rank
    FROM 
        TopTags r
    CROSS JOIN 
        RecentUsers u
    JOIN 
        ActiveUsers a ON u.DisplayName = a.ActiveUser
)
SELECT 
    TagName,
    QuestionsCount,
    ActiveUser,
    CommentsMade,
    TotalScore,
    Rank
FROM 
    FinalBenchmark
ORDER BY 
    Rank, CommentsMade DESC;
