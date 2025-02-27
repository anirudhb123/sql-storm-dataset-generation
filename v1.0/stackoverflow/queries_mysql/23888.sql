
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
CommentsWithTags AS (
    SELECT 
        C.Id AS CommentId,
        C.PostId,
        C.Text,
        C.UserDisplayName,
        GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM 
        Comments C
    LEFT JOIN 
        Posts P ON C.PostId = P.Id
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
        ) AS T ON TRUE
    GROUP BY 
        C.Id, C.PostId, C.Text, C.UserDisplayName
),
PostHistoryAggregation AS (
    SELECT
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate END) AS LastReopenDate,
        COUNT(DISTINCT PH.UserId) AS UniqueEditors
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
FinalResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.Tags,
        RP.Rank,
        CW.Tags AS CommentTags,
        PhC.CloseCount,
        PhC.LastReopenDate,
        PhC.UniqueEditors,
        (UPV.UpVotes - UPV.DownVotes) AS NetVotes
    FROM 
        RankedPosts RP
    LEFT JOIN 
        CommentsWithTags CW ON CW.PostId = RP.PostId
    LEFT JOIN 
        PostHistoryAggregation PhC ON PhC.PostId = RP.PostId
    LEFT JOIN 
        (SELECT 
            P.Id,
            SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Posts P
        LEFT JOIN 
            Votes V ON V.PostId = P.Id
        GROUP BY 
            P.Id) UPV ON UPV.Id = RP.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    Tags,
    Rank,
    COALESCE(CommentTags, 'No comments') AS CommentTags,
    COALESCE(CloseCount, 0) AS CloseCount,
    COALESCE(LastReopenDate, '1970-01-01') AS LastReopenDate,
    COALESCE(UniqueEditors, 0) AS UniqueEditors,
    NetVotes
FROM 
    FinalResults
WHERE 
    Rank <= 5 OR CloseCount > 0
ORDER BY 
    NetVotes DESC, CreationDate DESC;
