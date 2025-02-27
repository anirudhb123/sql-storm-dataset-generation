WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
PostVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 8 THEN 1 END) AS BountyVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalNegativeVotes
    FROM 
        Votes 
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(CASE WHEN PHT.Name = 'Edit Body' THEN PH.Comment END, '; ') AS EditComments
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
RankedPosts AS (
    SELECT 
        RP.*,
        (ROW_NUMBER() OVER (ORDER BY RP.Score DESC, RP.ViewCount DESC)) AS Rank,
        (UP.DownerVotes - UP.UpVotes) AS NetVotes,
        (UP.UpVotes + UP.BountyVotes) AS TotalPositiveEngagement
    FROM 
        RecentPosts RP
    LEFT JOIN 
        PostVotes UP ON RP.PostId = UP.PostId
)

SELECT 
    R.PostId,
    R.Title,
    R.OwnerDisplayName,
    R.OwnerReputation,
    R.CreationDate,
    R.ViewCount,
    R.Score,
    R.AnswerCount,
    R.CommentCount,
    COALESCE(PH.LastEditDate, 'Never Edited') AS LastEditDate,
    PH.EditComments,
    R.Rank,
    R.NetVotes,
    R.TotalPositiveEngagement
FROM 
    RankedPosts R
LEFT JOIN 
    PostHistoryDetails PH ON R.PostId = PH.PostId
WHERE 
    (R.NetVotes > 0 OR R.TotalPositiveEngagement > 0)
    AND R.Rank <= 100
ORDER BY 
    R.Rank;
