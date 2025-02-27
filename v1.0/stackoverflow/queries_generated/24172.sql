WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        V.PostId,
        V.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        V.PostId, V.VoteTypeId
),
TopVotedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.OwnerDisplayName,
        COALESCE(SUM(CASE WHEN RV.VoteTypeId = 2 THEN RV.VoteCount END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN RV.VoteTypeId = 3 THEN RV.VoteCount END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY RP.PostTypeId ORDER BY COALESCE(SUM(CASE WHEN RV.VoteTypeId = 2 THEN RV.VoteCount END), 0) - COALESCE(SUM(CASE WHEN RV.VoteTypeId = 3 THEN RV.VoteCount END), 0) DESC) AS PopularityRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        RecentVotes RV ON RP.PostId = RV.PostId
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.Score, RP.OwnerDisplayName
)
SELECT 
    T.VoteTypeId,
    COUNT(*) AS VoteDistribution,
    COUNT(DISTINCT TP.PostId) AS TotalPosts,
    STRING_AGG(DISTINCT TP.Title, '; ') AS PostTitles
FROM 
    Votes T
JOIN 
    TopVotedPosts TP ON T.PostId = TP.PostId
WHERE 
    T.UserId IS NOT NULL
GROUP BY 
    T.VoteTypeId
ORDER BY 
    VoteDistribution DESC
HAVING 
    COUNT(DISTINCT TP.PostId) > 3 
    OR COUNT(DISTINCT TP.PostId) IS NULL
UNION ALL
SELECT 
    0 AS VoteTypeId,
    COUNT(*) AS VoteDistribution,
    COUNT(DISTINCT TP.PostId) AS TotalPosts,
    STRING_AGG(DISTINCT TP.Title, '; ') AS PostTitles
FROM 
    Votes T
JOIN 
    TopVotedPosts TP ON T.PostId = TP.PostId
WHERE 
    T.UserId IS NULL
GROUP BY 
    T.VoteTypeId
HAVING 
    COUNT(DISTINCT TP.PostId) < 3;
