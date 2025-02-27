
WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS TagCount
    FROM 
        Posts P
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
             UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE 
            CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) AS T ON TRUE
    GROUP BY 
        P.Id
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditCount,
        COUNT(DISTINCT PH.PostId) AS EditedPostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id
),
PostWithMaxTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        TAG.TagCount
    FROM 
        Posts P
    JOIN 
        PostTagCounts TAG ON P.Id = TAG.PostId
    WHERE 
        TAG.TagCount = (SELECT MAX(TagCount) FROM PostTagCounts)
),
EngagedUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        E.UpVotes,
        E.CommentCount,
        E.EditCount,
        E.EditedPostCount
    FROM 
        Users U
    JOIN 
        UserEngagement E ON U.Id = E.UserId
    WHERE 
        E.UpVotes > 50 AND E.CommentCount > 10
)
SELECT 
    PM.PostId,
    PM.Title,
    PM.ViewCount,
    EU.DisplayName,
    EU.Reputation,
    EU.UpVotes,
    EU.CommentCount
FROM 
    PostWithMaxTags PM
JOIN 
    EngagedUsers EU ON EU.UpVotes = (SELECT MAX(UpVotes) FROM UserEngagement);
