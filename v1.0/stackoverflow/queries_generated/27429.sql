WITH TagAnalytics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Title,
        P.CreationDate,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        Tags T ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')::int[]) -- Assuming tags are stored like <tag1><tag2>
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, P.Title, P.CreationDate, T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        SUM(PostCount) AS TotalPosts,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        AVG(AvgScore) AS AverageScore
    FROM 
        TagAnalytics
    GROUP BY 
        TagName
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    T.TagName,
    T.TotalPosts,
    T.TotalUpVotes,
    T.TotalDownVotes,
    COALESCE(T.AverageScore, 0) AS AverageScore,
    CASE 
        WHEN T.TotalPosts > 50 THEN 'Hot'
        WHEN T.TotalPosts BETWEEN 20 AND 50 THEN 'Warm'
        ELSE 'Cool'
    END AS TagTemperature
FROM 
    TopTags T
WHERE 
    T.TotalUpVotes >= 20
ORDER BY 
    T.TotalUpVotes DESC;
