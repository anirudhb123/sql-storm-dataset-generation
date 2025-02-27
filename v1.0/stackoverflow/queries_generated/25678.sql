WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        ARRAY_AGG(DISTINCT Users.DisplayName) AS ContributingUsers,
        COUNT(DISTINCT Posts.OwnerUserId) AS UniqueAuthors
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),
RecentPostHistory AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        PostHistory.UserDisplayName,
        STRING_AGG(PostHistory.Text, '; ') AS EditHistory,
        MAX(PostHistory.CreationDate) AS LastEditDate
    FROM 
        Posts
    JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    WHERE 
        PostHistory.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, PostHistory.UserDisplayName
)
SELECT 
    T.TagName,
    T.PostCount,
    T.PositiveScoreCount,
    T.ContributingUsers,
    T.UniqueAuthors,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.LastEditDate,
    R.EditHistory
FROM 
    TagStatistics T
JOIN 
    RecentPostHistory R ON T.TagName IN (SELECT UNNEST(string_to_array(R.Title, ' ')))
ORDER BY 
    T.PostCount DESC, T.TagName;
