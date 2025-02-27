
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount, 
        U.DisplayName AS OwnerName, 
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        @row_num := IF(@prev_owner = P.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_owner := P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    JOIN 
        (SELECT @row_num := 0, @prev_owner := NULL) AS vars
    WHERE 
        P.PostTypeId = 1 AND 
        P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName, P.OwnerUserId
),
RecentPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, OwnerName, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
PostHistoryCTE AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PHT.Name AS ChangeType,
        PH.UserDisplayName,
        PH.Comment,
        @history_row_num := IF(@prev_post = PH.PostId, @history_row_num + 1, 1) AS HistoryRank,
        @prev_post := PH.PostId
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN 
        (SELECT @history_row_num := 0, @prev_post := NULL) AS history_vars
    WHERE 
        PHT.Name IN ('Edit Title', 'Edit Body', 'Post Closed', 'Post Reopened')
)
SELECT 
    R.PostId,
    R.Title,
    R.Score,
    R.ViewCount,
    R.OwnerName,
    COALESCE(R.UpVotes, 0) AS UpVotes,
    COALESCE(R.DownVotes, 0) AS DownVotes,
    PH.CreationDate AS LastEdited,
    PH.ChangeType,
    PH.UserDisplayName AS Editor,
    PH.Comment AS EditComment
FROM 
    RecentPosts R
LEFT JOIN 
    PostHistoryCTE PH ON R.PostId = PH.PostId AND PH.HistoryRank = 1
ORDER BY 
    R.Score DESC, 
    R.ViewCount DESC;
