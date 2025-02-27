
WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        TRIM(value) AS TagName,
        COUNT(P.Id) AS TagCount
    FROM 
        Posts P
    CROSS JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS value
        FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
             UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE 
            CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    ) AS value
    WHERE 
        P.Tags IS NOT NULL
    GROUP BY 
        P.Id, TagName
), 
TopTags AS (
    SELECT 
        TagName,
        SUM(TagCount) AS TotalCount
    FROM 
        PostTagCounts
    GROUP BY 
        TagName
    ORDER BY 
        TotalCount DESC
    LIMIT 10
), 
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
        LEFT JOIN Comments C ON U.Id = C.UserId
        LEFT JOIN Votes V ON U.Id = V.UserId
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
TagEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsTagged,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
        JOIN Posts P ON U.Id = P.OwnerUserId
        JOIN PostTagCounts TC ON P.Id = TC.PostId
    WHERE 
        TC.TagName IN (SELECT TagName FROM TopTags)
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    TE.DisplayName,
    TE.PostsTagged,
    TE.TotalViews,
    UE.CommentCount,
    UE.VoteCount
FROM 
    TagEngagement TE
JOIN 
    UserEngagement UE ON TE.UserId = UE.UserId
ORDER BY 
    TE.TotalViews DESC, 
    UE.VoteCount DESC;
