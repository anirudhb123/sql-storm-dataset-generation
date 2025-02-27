WITH TagUsage AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(Posts.CreationDate) AS LastUsageDate
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id IN (SELECT UNNEST(string_to_array(Tags, '><'))::int) 
    GROUP BY 
        Tags.TagName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS Author,
        P.CreationDate,
        T.TagName,
        COUNT(C) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    JOIN 
        Tags T ON T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '><'))::int)
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName, P.CreationDate, T.TagName
),
BenchmarkResults AS (
    SELECT 
        T.TagName,
        SUM(R.CommentCount) AS TotalComments,
        COUNT(DISTINCT R.PostId) AS PostCount,
        COUNT(DISTINCT R.Author) AS UniqueAuthors,
        AVG(EXTRACT(EPOCH FROM NOW() - R.CreationDate)) / 86400 AS AvgDaysSinceCreated
    FROM 
        RecentPosts R
    JOIN 
        TagUsage T ON R.TagName = T.TagName
    GROUP BY 
        T.TagName
)
SELECT 
    B.TagName,
    B.PostCount,
    B.TotalComments,
    B.UniqueAuthors,
    B.AvgDaysSinceCreated
FROM 
    BenchmarkResults B
ORDER BY 
    B.TotalComments DESC,
    B.PostCount DESC;
