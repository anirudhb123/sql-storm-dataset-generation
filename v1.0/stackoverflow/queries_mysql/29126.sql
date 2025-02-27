
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS Author,
        U.Reputation AS AuthorReputation,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS TagRank,
        GROUP_CONCAT(DISTINCT T.TagName) AS TagList
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE 
            CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) T 
    ON 
        true
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, U.Reputation, P.ViewCount, P.Score, P.Tags
),

MostVotedTags AS (
    SELECT 
        TagList,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    WHERE 
        TagRank = 1
    GROUP BY 
        TagList
    HAVING 
        COUNT(*) > 5 
),

FinalOutput AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Author,
        RP.AuthorReputation,
        RP.ViewCount,
        RP.Score,
        MT.TagList,
        RANK() OVER (ORDER BY RP.Score DESC) AS PostRank
    FROM 
        RankedPosts RP
    JOIN 
        MostVotedTags MT ON FIND_IN_SET(RP.TagList, MT.TagList) > 0
)

SELECT 
    FO.PostId,
    FO.Title,
    FO.Author,
    FO.AuthorReputation,
    FO.ViewCount,
    FO.Score,
    FO.TagList,
    FO.PostRank
FROM 
    FinalOutput FO
WHERE 
    FO.PostRank <= 10 
ORDER BY 
    FO.Score DESC, 
    FO.ViewCount DESC;
