WITH RECURSIVE ActiveUserScores AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        CreationDate,
        LastAccessDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
    WHERE 
        LastAccessDate >= NOW() - INTERVAL '1 month'
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.CreationDate,
        P.Title,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '3 months'
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId, P.CreationDate, P.Title
), 
PostMetrics AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COALESCE(RP.UpVotes, 0) AS UpVotes,
        COALESCE(RP.DownVotes, 0) AS DownVotes,
        COALESCE(RP.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COALESCE(RP.UpVotes, 0) DESC) AS UserPostRank
    FROM 
        Users U
    LEFT JOIN 
        RecentPosts RP ON U.Id = RP.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Rank,
    P.Title,
    P.UpVotes,
    P.DownVotes,
    P.CommentCount
FROM 
    ActiveUserScores U
LEFT JOIN 
    PostMetrics P ON U.UserId = P.UserId
WHERE 
    U.Rank <= 10 AND
    P.UserPostRank = 1
ORDER BY 
    U.Reputation DESC, 
    P.UpVotes DESC;
