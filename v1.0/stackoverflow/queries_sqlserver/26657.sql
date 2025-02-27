
WITH UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Users AS U
    JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    JOIN 
        (SELECT 
            P.Id, 
            value AS TagName
         FROM 
            Posts AS P 
         CROSS APPLY 
            STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><') AS value
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        (SELECT COUNT(*) FROM Comments AS C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts AS P
    LEFT JOIN 
        UserTags AS U ON P.OwnerUserId = U.UserId
    JOIN 
        (SELECT 
            UserId, 
            TagName
         FROM 
            UserTags 
         WHERE 
            TagName IN (SELECT TagName FROM TopTags)) AS T ON P.OwnerUserId = T.UserId
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
    PostStatistics AS PS
LEFT JOIN 
    Votes AS V ON PS.PostId = V.PostId 
LEFT JOIN 
    Users AS U ON PS.OwnerName = U.DisplayName
GROUP BY 
    PS.Title, PS.CreationDate, PS.ViewCount, PS.Score, PS.CommentCount, PS.TagName
ORDER BY 
    VoteCount DESC, PS.Score DESC;
