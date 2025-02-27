WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),
QualifiedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostsCount,
        CommentsCount,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC, PostsCount DESC) AS Rank
    FROM 
        UserActivity
    WHERE 
        Reputation > 1000 AND PostsCount >= 5
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > NOW() - INTERVAL '1 month'
)
SELECT 
    QU.DisplayName,
    QU.UpVotes,
    QU.DownVotes,
    PP.Title AS RecentPostTitle,
    PP.CreationDate AS RecentPostDate
FROM 
    QualifiedUsers QU
LEFT JOIN 
    RecentPosts PP ON QU.UserId = PP.OwnerUserId AND PP.rn = 1
ORDER BY 
    QU.Rank
LIMIT 10;
