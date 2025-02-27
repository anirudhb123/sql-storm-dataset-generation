WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        COUNT(C.Id) AS CommentsCount,
        AVG(V.VoteTypeId = 2) AS UpVotesCount,
        AVG(V.VoteTypeId = 3) AS DownVotesCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
RankedTopPosts AS (
    SELECT 
        TP.*,
        RANK() OVER (ORDER BY TP.Score DESC, TP.CommentsCount DESC) AS PostRank
    FROM 
        TopPosts TP
    WHERE 
        TP.Score > 0
)

SELECT 
    U.DisplayName,
    U.Reputation,
    RTP.Title,
    RTP.Score,
    RTP.CommentsCount,
    RTP.PostRank,
    CASE 
        WHEN RTP.PostRank <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    UserReputation U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    RankedTopPosts RTP ON P.Id = RTP.PostId
WHERE 
    U.Reputation >= (SELECT AVG(Reputation) FROM Users)
    AND RTP.PostRank <= 20
ORDER BY 
    U.Reputation DESC, RTP.Score DESC
LIMIT 50;
