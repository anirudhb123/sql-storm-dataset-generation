
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS Deletions
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), P.Id) AS DisplayPostId,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount,
        MAX(PH.CreationDate) AS LastUpdateDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostLinks PL ON PL.PostId = P.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.AcceptedAnswerId
),
RankedPosts AS (
    SELECT 
        PS.PostId, 
        PS.Title,
        PS.ViewCount, 
        PS.CommentCount, 
        PS.RelatedPostsCount,
        PS.LastUpdateDate,
        @row_num := @row_num + 1 AS ViewRank,
        @comment_rank := IF(PS.CommentCount > @prev_comment_count, @comment_rank + 1, @comment_rank) AS CommentRank,
        @prev_comment_count := PS.CommentCount
    FROM 
        PostStats PS, (SELECT @row_num := 0, @comment_rank := 0, @prev_comment_count := 0) AS vars
    ORDER BY 
        PS.ViewCount DESC, PS.CommentCount DESC
)

SELECT 
    UP.UserId,
    UP.DisplayName,
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CommentCount,
    RP.RelatedPostsCount,
    RP.LastUpdateDate,
    UP.UpVotes,
    UP.DownVotes,
    UP.Deletions,
    CASE 
        WHEN UP.UpVotes > UP.DownVotes THEN 'Positive'
        WHEN UP.UpVotes < UP.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN RP.CommentCount > 20 THEN 'Highly Discussed'
        WHEN RP.CommentCount BETWEEN 5 AND 20 THEN 'Moderately Discussed'
        ELSE 'Discussion Light'
    END AS DiscussionLevel
FROM 
    UserVoteCounts UP
INNER JOIN 
    RankedPosts RP ON RP.ViewRank <= 10 
WHERE 
    (UP.Deletions = 0 OR RP.CommentCount > 0)
ORDER BY 
    UP.UserId, RP.ViewCount DESC;
