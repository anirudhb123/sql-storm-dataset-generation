
WITH TagCounts AS (
    SELECT 
        TRIM(REGEXP_SUBSTR(Tags, '[^><]+', 1, seq)) AS TagName,
        PostTypeId,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 1000)) seq
    WHERE 
        PostTypeId = 1  
        AND seq <= ARRAY_SIZE(REGEXP_SPLIT_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))
    GROUP BY 
        TRIM(REGEXP_SUBSTR(Tags, '[^><]+', 1, seq)), PostTypeId
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
        ROW_NUMBER() OVER (ORDER BY TC.PostCount DESC) AS TagRank
    FROM 
        TagCounts TC
),

PopularUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.UpVotes,
        UR.DownVotes,
        UR.AnswersPosted,
        RANK() OVER (ORDER BY UR.UpVotes DESC) AS UserRank
    FROM 
        UserReputation UR
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
