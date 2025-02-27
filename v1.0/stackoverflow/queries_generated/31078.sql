WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        0 AS Level,
        CONVERT(varchar(100), P.Title) AS Path
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.CreationDate,
        P2.OwnerUserId,
        Level + 1,
        CONVERT(varchar(100), CTE.Path + ' -> ' + P2.Title)
    FROM 
        Posts P2
    INNER JOIN 
        Posts P ON P2.ParentId = P.Id
    INNER JOIN 
        RecursivePostCTE CTE ON P.Id = CTE.PostId
    WHERE 
        Level < 10 -- Limit recursion to avoid infinite loop
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CA.Id) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY COUNT(CA.Id) DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Posts CA ON CA.ParentId = P.Id AND CA.PostTypeId = 2 -- Join with answers
    LEFT JOIN 
        Votes V ON V.PostId = P.Id AND V.VoteTypeId = 8 -- Bounty votes
    WHERE 
        P.PostTypeId = 1 -- Questions only
    GROUP BY 
        P.Id, P.Title
),

TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.AnswerCount,
        PS.TotalBounties
    FROM 
        PostStatistics PS 
    WHERE 
        PS.Rank <= 10
),

PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(V.Id) AS VoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 -- Questions only
    GROUP BY 
        P.Id, P.Title
)

SELECT 
    T.Title,
    T.AnswerCount,
    T.TotalBounties,
    PVS.VoteCount,
    PVS.UpVotes,
    PVS.DownVotes,
    (SELECT STRING_AGG(CONVERT(varchar, UserId), ', ') 
     FROM (SELECT DISTINCT UserId FROM Badges WHERE UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = T.PostId)) AS DistinctUsers) AS BadgeOwners,
    RP.Path AS PostHierarchy
FROM 
    TopPosts T
LEFT JOIN 
    PostVoteSummary PVS ON T.PostId = PVS.PostId
LEFT JOIN 
    RecursivePostCTE RP ON T.PostId = RP.PostId
ORDER BY 
    T.TotalBounties DESC, T.AnswerCount DESC;
