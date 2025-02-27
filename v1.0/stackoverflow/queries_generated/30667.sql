WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Start with Questions

    UNION ALL

    SELECT 
        P2.Id,
        P2.Title,
        P2.ParentId,
        PH.Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostHierarchy PH ON P2.ParentId = PH.PostId
    WHERE 
        P2.PostTypeId = 2 -- Only Answers
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    GROUP BY 
        U.Id
),
TagPostStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score * P.ViewCount) AS AverageImpactScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    RPH.PostId,
    RPH.Title,
    RPH.Level,
    U.DisplayName AS Author,
    US.Upvotes,
    US.Downvotes,
    T.TagName,
    TPS.PostCount AS TagPostCount,
    TPS.AverageImpactScore
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    Users U ON RPH.PostId = U.Id
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    PostLinks PL ON RPH.PostId = PL.PostId
LEFT JOIN 
    Tags T ON PL.RelatedPostId = T.ExcerptPostId
LEFT JOIN 
    TagPostStats TPS ON T.TagName = TPS.TagName
WHERE 
    U.Reputation > 1000 -- Only include users with a reputation above 1000
ORDER BY 
    RPH.Level DESC, 
    US.Upvotes DESC;
