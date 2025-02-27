
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS UpVoteCount,
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS TagList
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2  
    LEFT JOIN 
        Tags T ON LOCATE(T.TagName, P.Tags) > 0   
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, U.DisplayName, P.CreationDate, P.ViewCount, P.Score
),
PostBenchmarks AS (
    SELECT 
        RP.*,
        CASE
            WHEN RP.ViewCount >= 1000 THEN 'High'
            WHEN RP.ViewCount >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS Popularity,
        CASE
            WHEN RP.Score >= 50 THEN 'Expert'
            WHEN RP.Score >= 20 THEN 'Intermediate'
            ELSE 'Novice'
        END AS ExpertiseLevel
    FROM 
        RankedPosts RP
),
FinalOutput AS (
    SELECT 
        PB.PostId,
        PB.Title,
        PB.Author,
        PB.CreationDate,
        PB.ViewCount,
        PB.UpVoteCount,
        PB.CommentCount,
        PB.TagList,
        PB.Popularity,
        PB.ExpertiseLevel
    FROM 
        PostBenchmarks PB
    ORDER BY 
        PB.ViewCount DESC, PB.Score DESC
    LIMIT 100  
)
SELECT 
    *,
    (SELECT COUNT(*) FROM Posts WHERE CreationDate >= CURDATE() - INTERVAL 1 YEAR) AS TotalPostsLastYear
FROM 
    FinalOutput;
