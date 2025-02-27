
WITH TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeVotes,
        AVG(p.ViewCount) AS AvgViews,
        GROUP_CONCAT(DISTINCT u.DisplayName SEPARATOR ', ') AS ActiveUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        PositiveVotes,
        NegativeVotes,
        AvgViews,
        ActiveUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagSummary
)
SELECT 
    TagName,
    PostCount,
    PositiveVotes,
    NegativeVotes,
    AvgViews,
    ActiveUsers
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
