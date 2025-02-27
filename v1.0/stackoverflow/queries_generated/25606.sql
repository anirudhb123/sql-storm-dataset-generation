WITH TagCounts AS (
    SELECT 
        trim(tag) AS TagName,
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS tag
        FROM 
            Posts
        WHERE 
            PostTypeId = 1
    ) AS tags
    GROUP BY 
        tag
),
TopTags AS (
    SELECT 
        TagName,
        PostCount
    FROM 
        TagCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS TotalVotes,
        COALESCE(SUM(C.CreationDate IS NOT NULL), 0) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id
    HAVING 
        COUNT(DISTINCT V.Id) > 10 OR COUNT(DISTINCT C.Id) > 5
),
PopularPostsByTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score AS PostScore,
        T.TagName
    FROM 
        Posts P
    JOIN 
        TopTags TT ON TT.TagName = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))
    WHERE 
        P.ViewCount > 1000
    ORDER BY 
        P.Score DESC
    LIMIT 5
)
SELECT 
    U.DisplayName AS AuthorName,
    SUM(E.TotalVotes) AS TotalUserVotes,
    SUM(E.TotalComments) AS TotalUserComments,
    GROUP_CONCAT(DISTINCT PP.Title) AS PopularPostTitles,
    T.TagName
FROM 
    UserEngagement E
JOIN 
    Posts P ON E.UserId = P.OwnerUserId
JOIN 
    PopularPostsByTags PP ON P.Id = PP.PostId
JOIN 
    TopTags T ON T.TagName = PP.TagName
GROUP BY 
    U.DisplayName, T.TagName
ORDER BY 
    TotalUserVotes DESC, TotalUserComments DESC;
