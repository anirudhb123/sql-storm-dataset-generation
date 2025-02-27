WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    COALESCE(PVS.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(PVS.DownVoteCount, 0) AS DownVoteCount,
    UBD.GoldCount,
    UBD.SilverCount,
    UBD.BronzeCount,
    RP.OwnerDisplayName,
    RP.Rank
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVoteSummary PVS ON RP.PostId = PVS.PostId
LEFT JOIN 
    UserBadges UBD ON RP.OwnerUserId = UBD.UserId
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.ViewCount DESC, RP.Score DESC;
