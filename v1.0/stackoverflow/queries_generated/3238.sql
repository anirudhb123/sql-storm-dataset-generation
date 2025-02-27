WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN (SELECT COUNT(*) FROM Votes V2 WHERE V2.PostId = RP.PostId AND V2.VoteTypeId = 2) > 
                 (SELECT COUNT(*) FROM Votes V2 WHERE V2.PostId = RP.PostId AND V2.VoteTypeId = 3)
            THEN 'Mostly Positive'
            ELSE 'Mixed/Negative'
        END AS VoteSentiment
    FROM 
        RankedPosts RP
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes
         GROUP BY PostId) V ON RP.PostId = V.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON RP.PostId = C.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.OwnerDisplayName,
    PD.UpVotes,
    PD.DownVotes,
    PD.CommentCount,
    PD.VoteSentiment
FROM 
    PostDetails PD
WHERE 
    PD.Rank <= 5
ORDER BY 
    PD.UpVotes DESC, PD.CreationDate DESC;

WITH TotalStats AS (
    SELECT
        U.Location,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Location
)
SELECT 
    TS.Location,
    TS.TotalPosts,
    TS.PositivePosts,
    ROUND((TS.PositivePosts::decimal / TS.TotalPosts) * 100, 2) AS PositivePostPercentage
FROM 
    TotalStats TS
WHERE 
    TS.TotalPosts > 10
ORDER BY 
    PositivePostPercentage DESC;
