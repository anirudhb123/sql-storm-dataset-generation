WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Only questions
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalQuestions,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    WHERE 
        U.LastAccessDate > NOW() - INTERVAL '6 months'
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        R.PostId,
        R.Title,
        R.ViewCount,
        R.AnswerCount,
        R.CommentCount,
        R.LastActivityDate,
        A.TotalQuestions,
        A.TotalViews
    FROM 
        RankedPosts R
    JOIN 
        ActiveUsers A ON R.OwnerDisplayName = A.DisplayName
    WHERE 
        R.Rank <= 5  -- Top 5 questions by views per user
)
SELECT 
    PM.Title,
    PM.ViewCount,
    PM.AnswerCount,
    PM.CommentCount,
    PM.LastActivityDate,
    SUM(PV.BountyAmount) AS TotalBounties,
    AVG(U.Reputation) AS AverageReputation
FROM 
    PostMetrics PM
LEFT JOIN 
    Votes V ON PM.PostId = V.PostId AND V.VoteTypeId = 8  -- BountyStart
LEFT JOIN 
    Users U ON PM.OwnerDisplayName = U.DisplayName
GROUP BY 
    PM.PostId, PM.Title, PM.ViewCount, PM.AnswerCount, PM.CommentCount, PM.LastActivityDate
ORDER BY 
    PM.ViewCount DESC;
