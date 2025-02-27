WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVotes
    FROM 
        Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END AS HasAcceptedAnswer,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 
                CASE WHEN P.AnswerCount > 0 THEN 'Answered' ELSE 'Unanswered' END 
        END AS PostStatus
    FROM 
        Posts P
),
ViewCountRanked AS (
    SELECT 
        PostId,
        ViewCount,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        PostSummary
),
AggregateTags AS (
    SELECT 
        Id,
        STRING_AGG(TagName, ', ') AS AllTags
    FROM 
        Tags
    GROUP BY Id
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        T.TagName
    FROM 
        Posts P
    JOIN LATERAL (
        SELECT 
            unnest(string_to_array(P.Tags, '>')) AS TagName
    ) T ON T.TagName IS NOT NULL
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.HasAcceptedAnswer,
    PS.PostStatus,
    UDS.DisplayName AS UserVoteHandler,
    UVD.UpVotes,
    UVD.DownVotes,
    CASE 
        WHEN PS.PostStatus = 'Closed' AND UVD.CloseVotes > 0 THEN 'Active Closure'
        ELSE 'Normal'
    END AS ClosureStatus,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PS.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = PS.PostId AND PH.PostHistoryTypeId IN (10, 11)) AS ClosureHistory,
    R.ViewRank AS RankBasedOnViews,
    STRING_AGG(DISTINCT PT.TagName, ', ') AS RelatedTags
FROM 
    PostSummary PS
LEFT JOIN UserVoteSummary UVD ON PS.PostId = UVD.UserId
LEFT JOIN Users UDS ON PS.PostId = UDS.Id
LEFT JOIN ViewCountRanked R ON PS.PostId = R.PostId
LEFT JOIN PostTags PT ON PS.PostId = PT.PostId
WHERE 
    PS.ViewCount > 10 AND 
    (PS.HasAcceptedAnswer = 1 OR PS.PostStatus = 'Unanswered')
GROUP BY 
    PS.PostId, PS.Title, PS.CreationDate, PS.Score, PS.ViewCount, 
    PS.HasAcceptedAnswer, PS.PostStatus, UDS.DisplayName, UVD.UpVotes, 
    UVD.DownVotes, R.ViewRank
ORDER BY 
    PS.CreationDate DESC, PS.Score DESC;
