WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(P.AcceptedAnswerId, -1) AS HasAcceptedAnswer,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.AcceptedAnswerId
),
PostHistoryData AS (
    SELECT 
        PH.PostId,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11)) AS TotalCloseReopenActions,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 12) AS TotalDeletions,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 24) AS TotalEditSuggestions
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    R.HasAcceptedAnswer,
    R.CommentCount,
    R.UpVotes,
    R.DownVotes,
    PH.TotalCloseReopenActions,
    PH.TotalDeletions,
    PH.TotalEditSuggestions,
    U.BadgesCount,
    CASE 
        WHEN R.UserPostRank = 1 THEN 'Most Recent'
        WHEN R.UserPostRank <= 5 THEN 'Top 5 Recent Posts'
        ELSE 'Others'
    END AS PostCategory,
    CASE 
        WHEN R.Score > 10 THEN 'High Score'
        WHEN R.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreClassification,
    STRING_AGG(T.TagName, ', ') AS Tags
FROM 
    RecentPosts R
LEFT JOIN 
    PostHistoryData PH ON PH.PostId = R.PostId
LEFT JOIN 
    Users U ON R.OwnerUserId = U.Id
LEFT JOIN 
    Posts P ON R.PostId = P.Id
LEFT JOIN 
    unnest(string_to_array(P.Tags, ',')) AS T(TagName) ON TRUE  -- splitting tags into rows
WHERE 
    (R.Score IS NOT NULL AND R.Score > 2) OR (R.CommentCount > 0)
GROUP BY 
    R.PostId, R.Title, R.CreationDate, R.Score, R.HasAcceptedAnswer, 
    R.CommentCount, R.UpVotes, R.DownVotes, PH.TotalCloseReopenActions, 
    PH.TotalDeletions, PH.TotalEditSuggestions, U.BadgesCount
HAVING 
    COUNT(CASE WHEN R.HasAcceptedAnswer = -1 THEN 1 END) = 0  -- ensure we have at least one accepted answer
ORDER BY 
    R.CreationDate DESC
LIMIT 100;
