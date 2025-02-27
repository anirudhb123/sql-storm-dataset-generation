WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
), 
TopQuestions AS (
    SELECT 
        PostId, 
        Title,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5 AND P.PostTypeId = 1
), 
TopAnswers AS (
    SELECT 
        PostId,
        COUNT(*) AS AnswerCount
    FROM 
        Posts
    WHERE 
        ParentId IN (SELECT PostId FROM TopQuestions)
    GROUP BY 
        PostId
), 
PostEngagement AS (
    SELECT 
        TQ.PostId, 
        TQ.Title, 
        TQ.OwnerDisplayName, 
        TQ.Score, 
        TQ.ViewCount,
        COALESCE(TA.AnswerCount, 0) AS AnswerCount
    FROM 
        TopQuestions TQ
    LEFT JOIN 
        TopAnswers TA ON TQ.PostId = TA.PostId
)
SELECT 
    PE.PostId,
    PE.Title,
    PE.OwnerDisplayName,
    PE.Score,
    PE.ViewCount,
    PE.AnswerCount,
    COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
    AVG(U.Reputation) AS AverageReputation
FROM 
    PostEngagement PE
LEFT JOIN 
    Votes V ON PE.PostId = V.PostId AND V.VoteTypeId = 8
LEFT JOIN 
    Users U ON PE.OwnerDisplayName = U.DisplayName
GROUP BY 
    PE.PostId, PE.Title, PE.OwnerDisplayName, PE.Score, PE.ViewCount, PE.AnswerCount
ORDER BY 
    PE.Score DESC, PE.ViewCount DESC;
