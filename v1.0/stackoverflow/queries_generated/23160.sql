WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    uvs.UserId,
    uvs.DisplayName,
    uvs.UpVotesCount,
    uvs.DownVotesCount,
    uvs.TotalPosts,
    uvs.TotalComments,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score
FROM 
    UserVoteStats uvs
LEFT JOIN 
    RecentPosts rp ON uvs.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
WHERE 
    uvs.UpVotesCount - uvs.DownVotesCount > 10
    AND (SELECT COUNT(*) FROM Badges b WHERE b.UserId = uvs.UserId AND b.Class = 1) > 0
ORDER BY 
    uvs.Rank,
    rp.CreationDate DESC
LIMIT 100;

-- The query aggregates user voting statistics on posts, joining various related entities.
-- It limits the results to users with a positive net vote difference greater than 10,
-- who also possess at least one gold badge.
-- Additionally, it retrieves recent posts made by those users within the last 30 days,
-- ordering results primarily by user ranking and then by creation date of the post.
