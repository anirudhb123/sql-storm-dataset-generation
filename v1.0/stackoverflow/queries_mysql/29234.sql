
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        GROUP_CONCAT(DISTINCT p.Title SEPARATOR ', ') AS TopPostTitles,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Tags AS t
    JOIN 
        Posts AS p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Comments AS c ON c.PostId = p.Id
    LEFT JOIN 
        Votes AS v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR) 
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        HighViewCountPosts,
        TotalComments,
        TotalBountyAmount,
        @row_number := IFNULL(@row_number, 0) + 1 AS Rank
    FROM 
        TagStats, (SELECT @row_number := 0) AS rn
    ORDER BY 
        PostCount DESC, HighViewCountPosts DESC
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.HighViewCountPosts,
    tt.TotalComments,
    tt.TotalBountyAmount,
    tt.Rank,
    CASE 
        WHEN tt.PostCount > 100 THEN 'High Activity'
        WHEN tt.PostCount BETWEEN 51 AND 100 THEN 'Moderate Activity'
        ELSE 'Low Activity' 
    END AS ActivityLevel
FROM 
    TopTags AS tt
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.Rank;
