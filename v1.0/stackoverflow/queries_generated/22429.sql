WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(V.CreationDate IS NOT NULL) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(AVG(U.Reputation), 0) AS AverageReputation,
        MAX(P.CreationDate) OVER (PARTITION BY P.Id) AS LastModified
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.PostTypeId, P.Title
),
PostHistoryWithOpened AS (
    SELECT
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        PHT.Name AS HistoryTypeName
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Name IN ('Post Reopened', 'Post Closed')
),
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.VoteCount,
        ROW_NUMBER() OVER (ORDER BY ps.VoteCount DESC) AS PopularityRank
    FROM 
        PostStats ps
    WHERE 
        ps.CommentCount > 5 AND 
        ps.VoteCount > 10
)

SELECT 
    pp.Title,
    pp.CommentCount,
    pp.VoteCount,
    COALESCE(ph.UserId, 'No user') AS UserId,
    ph.CreationDate AS HistoryDate,
    ph.HistoryTypeName,
    CASE 
        WHEN pp.VoteCount > 100 THEN 'Hot Post'
        WHEN pp.VoteCount BETWEEN 51 AND 100 THEN 'Trending'
        ELSE 'Normal Post'
    END AS PostCategory
FROM 
    PopularPosts pp
LEFT JOIN 
    PostHistoryWithOpened ph ON pp.PostId = ph.PostId
WHERE 
    pp.PopularityRank <= 10 OR ph.HistoryTypeName IS NULL
ORDER BY 
    pp.VoteCount DESC, pp.CommentCount DESC;
