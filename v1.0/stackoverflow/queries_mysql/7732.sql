
WITH RankedPosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        U.DisplayName AS OwnerName, 
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.Score
),
PopularTags AS (
    SELECT 
        DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(T.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts T
    JOIN 
        (SELECT a.N + b.N * 10 + 1 AS n FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
             UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
             UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) n
    ON n.n <= CHAR_LENGTH(T.Tags) - CHAR_LENGTH(REPLACE(T.Tags, '><', '')) + 1
    WHERE 
        T.PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    RP.OwnerName, 
    RP.Title, 
    TAGS.TagName, 
    RP.CommentCount, 
    RP.Score,
    RP.CreationDate
FROM 
    RankedPosts RP
JOIN 
    TagStatistics TAGS ON RP.Title LIKE CONCAT('%', TAGS.TagName, '%')
WHERE 
    RP.PostRank <= 3
ORDER BY 
    RP.Score DESC, 
    RP.CommentCount DESC;
