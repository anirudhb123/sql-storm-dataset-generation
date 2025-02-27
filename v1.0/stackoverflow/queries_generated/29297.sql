WITH PostTagStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Tags,
        SPLIT_PART(tag, '>', 2) AS IndividualTag,
        COUNT(*) AS TagUsage
    FROM 
        Posts P
    CROSS JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><') AS tag
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, P.CreationDate, P.Tags, tag
),
PostWithMostTags AS (
    SELECT 
        PostId, 
        COUNT(DISTINCT IndividualTag) AS UniqueTagsCount
    FROM 
        PostTagStatistics
    GROUP BY 
        PostId
    ORDER BY 
        UniqueTagsCount DESC
    LIMIT 5
),
UserPostStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserWithMostPosts AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        Wikis
    FROM 
        UserPostStatistics
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.Wikis,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    TS.IndividualTag,
    TS.TagUsage
FROM 
    UserWithMostPosts U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
JOIN 
    PostTagStatistics TS ON P.Id = TS.PostId
WHERE 
    P.Id IN (SELECT PostId FROM PostWithMostTags)
ORDER BY 
    U.TotalPosts DESC, TS.TagUsage DESC;
