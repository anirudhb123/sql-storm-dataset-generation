WITH TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeVotes,
        AVG(p.ViewCount) AS AvgViews,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
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

This SQL query generates a report summarizing the top 10 tags used in posts created within the last year. It counts the total number of posts associated with each tag, calculates the number of positive and negative votes, computes the average views per post, and lists the distinct active users who have contributed posts with these tags. The results are ordered by the count of posts associated with each tag, providing a comprehensive overview of the most popular tags in terms of engagement and activity.
