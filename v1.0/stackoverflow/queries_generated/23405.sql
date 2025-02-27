WITH PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
PostScore AS (
    SELECT 
        Id,
        COALESCE(Score, 0) + COALESCE(UpVotes, 0) - COALESCE(DownVotes, 0) AS TotalScore
    FROM Posts 
    LEFT JOIN PostVoteCounts PVC ON Posts.Id = PVC.PostId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseVotes,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM PostHistory PH 
    WHERE PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY PH.PostId
),
PostDetails AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        PS.TotalScore,
        COALESCE(CP.CloseVotes, 0) AS CloseVotes,
        COALESCE(CP.LastCloseDate, P.CreationDate) AS LastCloseDate
    FROM Posts P
    LEFT JOIN PostScore PS ON P.Id = PS.Id
    LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
)
SELECT 
    PD.Id AS PostId,
    PD.Title,
    PD.CreationDate,
    PD.TotalScore,
    PD.CloseVotes,
    CASE 
        WHEN PD.CloseVotes > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM PostDetails PD
LEFT JOIN STRING_TO_ARRAY(PD.Tags, ',') AS TagArray ON TRUE
JOIN Tags T ON T.TagName = TRIM(TagArray) 
WHERE PD.TotalScore >= 10
AND PD.LastCloseDate < NOW() - INTERVAL '30 days'
GROUP BY PD.Id, PD.Title, PD.CreationDate, PD.TotalScore, PD.CloseVotes
ORDER BY PD.TotalScore DESC, PD.CreationDate ASC;  
