WITH RecursiveUserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(V.VoteTypeId, 0) AS VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY V.CreationDate DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
),
ActiveUsers AS (
    SELECT 
        UserId,
        Reputation,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        RecursiveUserVotes
    WHERE 
        VoteRank = 1 -- Get the most recent vote per user
    GROUP BY 
        UserId, Reputation
),
PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(C.CommentCount, 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) C ON P.Id = C.PostId
),
EligiblePosts AS (
    SELECT 
        PW.PostId,
        PW.Title,
        PW.OwnerUserId,
        COALESCE(U.Reputation, 0) AS OwnerReputation,
        PW.CommentCount
    FROM 
        PostsWithComments PW
    JOIN 
        ActiveUsers U ON PW.OwnerUserId = U.UserId
    WHERE 
        U.Reputation > 1000 -- Filtering users with reputations greater than 1000
),
RankedEligiblePosts AS (
    SELECT 
        EP.*,
        RANK() OVER (ORDER BY EP.CommentCount DESC, EP.OwnerReputation DESC) AS Rank
    FROM 
        EligiblePosts EP
)
SELECT 
    REP.PostId,
    REP.Title,
    REP.OwnerUserId,
    REP.OwnerReputation,
    REP.CommentCount,
    REP.Rank
FROM 
    RankedEligiblePosts REP
WHERE 
    REP.Rank <= 10 -- Getting the top 10 ranked posts
ORDER BY 
    REP.Rank;
