WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        COALESCE(SUM(V.VoteTypeId = 2) OVER (PARTITION BY P.Id), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3) OVER (PARTITION BY P.Id), 0) AS DownVotes,
        (COALESCE(SUM(V.VoteTypeId = 2) OVER (PARTITION BY P.Id), 0) - COALESCE(SUM(V.VoteTypeId = 3) OVER (PARTITION BY P.Id), 0)) AS Score,
        COUNT(C.ID) AS CommentCount,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
PostMetrics AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        UpVotes, 
        DownVotes, 
        Score, 
        CommentCount,
        RANK() OVER (ORDER BY Score DESC) AS RankScore
    FROM 
        RankedPosts
)
SELECT 
    PM.Title, 
    PM.CreationDate, 
    PM.UpVotes, 
    PM.DownVotes, 
    PM.Score, 
    PM.CommentCount,
    CASE 
        WHEN PM.RankScore <= 10 THEN 'Top 10 Posts'
        WHEN PM.RankScore > 10 AND PM.RankScore <= 20 THEN 'Next 10 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    PostMetrics PM
WHERE 
    PM.UpVotes IS NOT NULL OR PM.DownVotes IS NOT NULL
ORDER BY 
    PM.RankScore;
