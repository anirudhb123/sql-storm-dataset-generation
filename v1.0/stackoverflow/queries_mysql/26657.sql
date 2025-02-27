
WITH UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        (SELECT 
            P.Id, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            Posts P 
         INNER JOIN 
            (SELECT 
                1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
                SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
            ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
         WHERE 
            P.PostTypeId = 1) AS T ON P.Id = T.Id
    GROUP BY 
        U.Id, U.DisplayName, T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        SUM(PostCount) AS TotalPosts
    FROM 
        UserTags
    GROUP BY 
        TagName
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        P.Score, 
        T.TagName,
        U.DisplayName AS OwnerName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        UserTags U ON P.OwnerUserId = U.UserId
    JOIN 
        (SELECT 
            UserId, 
            TagName
         FROM 
            UserTags 
         WHERE 
            TagName IN (SELECT TagName FROM TopTags)) T ON P.OwnerUserId = T.UserId
    WHERE 
        P.PostTypeId = 1
)
SELECT 
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.TagName,
    COUNT(V.Id) AS VoteCount,
    AVG(U.Reputation) AS AvgReputation
FROM 
    PostStatistics PS
LEFT JOIN 
    Votes V ON PS.PostId = V.PostId 
LEFT JOIN 
    Users U ON PS.OwnerName = U.DisplayName
GROUP BY 
    PS.Title, PS.CreationDate, PS.ViewCount, PS.Score, PS.CommentCount, PS.TagName
ORDER BY 
    VoteCount DESC, PS.Score DESC;
