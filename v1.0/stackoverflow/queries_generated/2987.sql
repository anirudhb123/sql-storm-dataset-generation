WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        U.Id AS OwnerId,
        DENSE_RANK() OVER (ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostSummary AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.ViewCount,
        PD.AnswerCount,
        PD.CommentCount,
        PD.OwnerDisplayName,
        PD.PostRank,
        U.DisplayName AS UpVoteUser
    FROM 
        PostDetails PD
    LEFT JOIN 
        Votes V ON PD.PostId = V.PostId AND V.VoteTypeId = 2
    LEFT JOIN 
        Users U ON V.UserId = U.Id
)
SELECT 
    PS.Title,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerDisplayName,
    US.DisplayName AS TopVoter,
    US.TotalBounty,
    US.UpVotes,
    US.DownVotes,
    (CASE 
        WHEN PS.ViewCount > 1000 THEN 'High'
        WHEN PS.ViewCount BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END) AS ViewCountCategory,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PS.PostId) AS TotalComments
FROM 
    PostSummary PS
JOIN 
    UserScore US ON PS.OwnerId = US.UserId
WHERE 
    PS.PostRank <= 10
ORDER BY 
    PS.ViewCount DESC, US.Reputation DESC;
