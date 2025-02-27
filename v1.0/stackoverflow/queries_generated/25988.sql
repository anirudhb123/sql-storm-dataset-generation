WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RankByDate,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1  -- Only Questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(PT.PostId) AS PostCount,
        SUM(COALESCE(PH.VoteCount, 0)) AS TotalVotes,
        AVG(P.Score) AS AvgScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, '><')::int[])  -- Assuming Tags stored in format <tag1><tag2>...
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) PH ON P.Id = PH.PostId
    GROUP BY 
        T.TagName
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.RankByScore,
        RP.RankByDate,
        TS.PostCount,
        TS.TotalVotes,
        TS.AvgScore
    FROM 
        RankedPosts RP
    JOIN 
        TagStatistics TS ON TS.PostCount > 10  -- Filtering Tags that have more than 10 posts
    WHERE 
        RP.UpVotes > 5  -- Only keep posts with more than 5 upvotes
)

SELECT 
    FP.PostId,
    FP.Title,
    FP.OwnerDisplayName,
    FP.RankByScore,
    FP.RankByDate,
    FP.PostCount,
    FP.TotalVotes,
    FP.AvgScore,
    'Processed at ' || to_char(current_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS ProcessedTime
FROM 
    FilteredPosts FP
ORDER BY 
    FP.RankByScore DESC, 
    FP.RankByDate DESC
LIMIT 100;  -- Get the top 100 posts based on score and creation date
