WITH RecursivePostsCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL  -- Start with top-level questions
    UNION ALL
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostsCTE R ON P.ParentId = R.PostId  -- Join to find answers
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- Bounty Start and Close
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryAggregates AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS EditTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.Questions,
        U.Answers,
        U.TotalComments,
        U.TotalBounty,
        RCTE.PostId,
        RCTE.Title,
        RCTE.Score,
        RCTE.ViewCount,
        PH.EditCount,
        PH.LastEdited
    FROM 
        UserPostStats U
    INNER JOIN 
        RecursivePostsCTE RCTE ON U.UserId = RCTE.OwnerUserId
    LEFT JOIN 
        PostHistoryAggregates PH ON RCTE.PostId = PH.PostId
    WHERE 
        U.TotalPosts > 0 
        AND U.TotalBounty > 100
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalComments,
    U.TotalBounty,
    T.Title,
    T.Score,
    T.ViewCount,
    T.EditCount,
    T.LastEdited,
    RANK() OVER (ORDER BY U.TotalBounty DESC) AS UserRank
FROM 
    TopUsers U
JOIN 
    RecursivePostsCTE T ON U.PostId = T.PostId
WHERE 
    T.Score > (SELECT AVG(Score) FROM Posts) -- Only include posts better than average in score
ORDER BY 
    U.TotalBounty DESC, T.ViewCount DESC;
