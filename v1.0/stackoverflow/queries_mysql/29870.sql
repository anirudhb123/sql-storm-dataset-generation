
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        AVG(COALESCE(V.VoteCount, 0)) AS AverageVotes
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalAnswers,
        TotalComments,
        AverageVotes,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rownum := 0) r
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalAnswers,
    T.TotalComments,
    T.AverageVotes
FROM 
    TopTags T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.PostCount DESC;
