WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        TotalBounty,
        RANK() OVER (ORDER BY PostCount DESC, Reputation DESC) AS Rank
    FROM 
        UserStats
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Score DESC, UpVotes DESC) AS Rank
    FROM 
        PostDetails
)

SELECT 
    TU.Rank AS UserRank,
    TU.DisplayName AS UserName,
    TU.Reputation AS UserReputation,
    TP.Rank AS PostRank,
    TP.Title AS PostTitle,
    TP.Score AS PostScore,
    TP.CommentCount AS PostCommentCount,
    TP.UpVotes AS PostUpVotes,
    TP.DownVotes AS PostDownVotes
FROM 
    TopUsers TU
JOIN 
    TopPosts TP ON TU.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
WHERE 
    TU.Rank <= 10 AND TP.Rank <= 10
ORDER BY 
    TU.Rank, TP.Rank;
