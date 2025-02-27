WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
CloseReasonVotes AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.Comment END) AS CloseReasonId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
PostStats AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        COALESCE(CRV.CloseReasonId, 'N/A') AS CloseReason,
        COALESCE(CRV.CloseVoteCount, 0) AS CloseVoteCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        CloseReasonVotes CRV ON RP.PostId = CRV.PostId
),
CommentsWithVotes AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Comments C
    LEFT JOIN 
        Votes V ON C.PostId = V.PostId
    GROUP BY 
        C.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CloseReason,
    PS.CloseVoteCount,
    CW.CommentCount,
    CW.UpVotes,
    CW.DownVotes,
    CASE 
        WHEN PS.CloseVoteCount > 0 THEN 'Closed' 
        WHEN PS.Score > 10 THEN 'Popular' 
        WHEN PS.ViewCount BETWEEN 0 AND 100 THEN 'Newbie' 
        ELSE 'Regular' 
    END AS PostCategory,
    CASE 
        WHEN PS.ViewCount IS NULL THEN 'No Views' 
        WHEN PS.ViewCount = 0 THEN 'Unseen' 
        ELSE 'Seen' 
    END AS ViewStatus,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsInPost
FROM 
    PostStats PS
LEFT JOIN 
    CommentsWithVotes CW ON PS.PostId = CW.PostId
LEFT JOIN 
    Posts P ON PS.PostId = P.Id
LEFT JOIN 
    (SELECT DISTINCT UNNEST(string_to_array(P.Tags, ',')) AS TagName FROM Posts P) T ON T.TagName IS NOT NULL
GROUP BY 
    PS.PostId, PS.Title, PS.Score, PS.ViewCount, PS.CloseReason, PS.CloseVoteCount, CW.CommentCount, CW.UpVotes, CW.DownVotes
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;
