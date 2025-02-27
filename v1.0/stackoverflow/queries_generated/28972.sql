WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(Users.Reputation) AS AverageUserReputation
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageUserReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
),
RecentPosts AS (
    SELECT 
        Posts.Title,
        Posts.CreationDate,
        Posts.ViewCount,
        Tags.TagName
    FROM 
        Posts
    JOIN 
        Tags ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.AverageUserReputation,
    R.Title AS RecentPostTitle,
    R.CreationDate AS RecentPostDate,
    R.ViewCount AS RecentPostViewCount
FROM 
    TopTags T
LEFT JOIN 
    RecentPosts R ON T.TagName = R.TagName
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Rank, R.CreationDate DESC;
