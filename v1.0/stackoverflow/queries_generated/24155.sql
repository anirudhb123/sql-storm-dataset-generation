WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        V.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM Users U
    JOIN Votes V ON U.Id = V.UserId
    WHERE V.CreationDate > CURRENT_DATE - INTERVAL '1 month'
    GROUP BY U.Id, U.DisplayName, V.VoteTypeId
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId IN (12, 13)) AS DeleteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RankByUser
    FROM Posts P 
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.CreationDate
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.TotalBounties,
        PS.CommentCount,
        PS.DeleteCount,
        PS.RankByUser,
        ROW_NUMBER() OVER (ORDER BY PS.TotalBounties DESC, PS.CommentCount DESC) AS OverallRank
    FROM PostStats PS
    WHERE PS.RankByUser <= 3
)
SELECT 
    U.DisplayName,
    TP.Title,
    TP.ViewCount,
    TP.TotalBounties,
    TP.CommentCount,
    TP.DeleteCount,
    COALESCE(UV.VoteCount, 0) AS TotalVotes,
    CASE 
        WHEN TP.DeleteCount > 0 THEN 'Post Deleted'
        ELSE 'Active Post'
    END AS PostStatus,
    ARRAY_AGG(DISTINCT T.TagName) AS RelatedTags
FROM TopPosts TP
LEFT JOIN Users U ON TP.RankByUser <= 3 AND U.Id = TP.PostId
LEFT JOIN UserVotes UV ON U.Id = UV.UserId
LEFT JOIN LATERAL (
    SELECT 
        T.TagName
    FROM Tags T
    JOIN LATERAL (
        SELECT UNNEST(string_to_array(P.Tags, '><')) AS Tag 
        WHERE P.PostTypeId = 1 -- Only for questions
    ) AS TagsArray ON T.TagName = TagsArray.Tag
) AS T ON TP.PostId = T.Id
GROUP BY U.DisplayName, TP.Title, TP.ViewCount, TP.TotalBounties, TP.CommentCount, TP.DeleteCount
HAVING SUM(COALESCE(TP.DeleteCount, 0)) > 0
ORDER BY TotalVotes DESC, TP.ViewCount DESC;
