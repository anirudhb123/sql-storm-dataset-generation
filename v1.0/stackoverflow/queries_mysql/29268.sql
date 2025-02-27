
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        PostTypeId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName, PostTypeId
),

UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS AnswersPosted
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2  
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),

RankedTags AS (
    SELECT 
        TC.TagName,
        TC.PostCount,
        @rank := @rank + 1 AS TagRank
    FROM 
        TagCounts TC, (SELECT @rank := 0) r
    ORDER BY 
        TC.PostCount DESC
),

PopularUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.UpVotes,
        UR.DownVotes,
        UR.AnswersPosted,
        @userRank := @userRank + 1 AS UserRank
    FROM 
        UserReputation UR, (SELECT @userRank := 0) r
)

SELECT 
    RT.TagName,
    RT.PostCount,
    PU.DisplayName,
    PU.UpVotes,
    PU.DownVotes,
    PU.AnswersPosted,
    RT.TagRank,
    PU.UserRank
FROM 
    RankedTags RT
JOIN 
    PopularUsers PU ON PU.AnswersPosted > 0  
WHERE 
    RT.TagRank <= 10  
ORDER BY 
    RT.TagRank, PU.UserRank;
