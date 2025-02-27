WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(VB.BountyAmount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(COALESCE(VB.BountyAmount, 0)) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes VB ON P.Id = VB.PostId AND VB.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    WHERE 
        U.Reputation > 0 AND 
        U.LastAccessDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounty,
        ActivityRank
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
), PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        C.CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotesCount,  -- Assuming VoteTypeId 2 means upvote
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotesCount -- Assuming VoteTypeId 3 means downvote
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, C.CommentCount
), CombinedStats AS (
    SELECT 
        TU.DisplayName,
        TU.TotalBounty,
        PS.Title,
        PS.ViewCount,
        PS.CommentCount,
        PS.UpVotesCount,
        PS.DownVotesCount
    FROM 
        TopUsers TU
    JOIN 
        PostStats PS ON PS.ViewCount > 50  -- Post must have at least 50 views
    ORDER BY 
        TU.TotalBounty DESC, 
        PS.ViewCount DESC
)
SELECT 
    DisplayName,
    TotalBounty,
    Title,
    ViewCount,
    CommentCount,
    UpVotesCount,
    DownVotesCount,
    CASE 
        WHEN UpVotesCount > DownVotesCount THEN 'Positive'
        WHEN UpVotesCount < DownVotesCount THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    CombinedStats
WHERE 
    TotalBounty > 0
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;  -- Limit result to top 10 entries
