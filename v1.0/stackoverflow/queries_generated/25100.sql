WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.VoteTypeId = 2, 0)::int) AS TotalUpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)::int) AS TotalDownVotes,
        AVG(U.Reputation) AS AvgUserReputation
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId IN (4, 5, 6)) AS EditCount,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 11) AS ReopenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
FilteredPostStats AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        PS.PostCount,
        PS.TotalUpVotes,
        PS.TotalDownVotes,
        PS.AvgUserReputation,
        PH.LastEditDate,
        PH.EditCount,
        PH.CloseCount,
        PH.ReopenCount
    FROM 
        Posts P
    JOIN 
        TagStatistics PS ON P.Tags IS NOT NULL
    LEFT JOIN 
        PostHistoryDetails PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1 -- Only questions
        AND P.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
)
SELECT 
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    PostCount,
    TotalUpVotes,
    TotalDownVotes,
    AvgUserReputation,
    LastEditDate,
    EditCount,
    CloseCount,
    ReopenCount
FROM 
    FilteredPostStats
ORDER BY 
    Score DESC, 
    ViewCount DESC
LIMIT 100;
