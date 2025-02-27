
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS Owner,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS RankPerTag,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR) 
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName, P.CreationDate, P.Score, P.ViewCount, P.Tags
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT RP.PostId) AS NumberOfQuestions,
        AVG(RP.Score) AS AverageScore,
        SUM(RP.UpVotes) AS TotalUpVotes,
        SUM(RP.DownVotes) AS TotalDownVotes
    FROM 
        RankedPosts RP
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(RP.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
           (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
            UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         WHERE 
           CHAR_LENGTH(RP.Tags) - CHAR_LENGTH(REPLACE(RP.Tags, '><', '')) >= numbers.n - 1) AS T 
    ON T.TagName IS NOT NULL
    GROUP BY 
        T.TagName
)
SELECT 
    TS.TagName,
    TS.NumberOfQuestions,
    TS.AverageScore,
    TS.TotalUpVotes,
    TS.TotalDownVotes,
    CASE 
        WHEN TS.AverageScore >= 10 THEN 'High'
        WHEN TS.AverageScore BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    TagStats TS
WHERE 
    TS.NumberOfQuestions > 5 
ORDER BY 
    TS.TotalUpVotes DESC, 
    TS.AverageScore DESC;
