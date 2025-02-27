
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_owner_user_id = P.OwnerUserId, @row_number + 1, 1) AS OwnerRank,
        @prev_owner_user_id := P.OwnerUserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts P 
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, P.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PHT.Name AS HistoryType,
        PH.CreationDate AS HistoryDate,
        @change_row_number := IF(@prev_post_id = PH.PostId, @change_row_number + 1, 1) AS ChangeRank,
        @prev_post_id := PH.PostId
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    CROSS JOIN (SELECT @change_row_number := 0, @prev_post_id := NULL) AS vars
    WHERE 
        PH.CreationDate > NOW() - INTERVAL 1 MONTH
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RP.OwnerRank,
    RP.UpVoteCount,
    RP.DownVoteCount,
    RPH.HistoryType,
    RPH.HistoryDate
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentPostHistory RPH ON RP.PostId = RPH.PostId AND RPH.ChangeRank = 1
WHERE 
    RP.OwnerRank <= 3 
ORDER BY 
    RP.OwnerDisplayName, RP.Score DESC;
