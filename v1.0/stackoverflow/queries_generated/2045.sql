WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
        AND P.Score > 10
),
PostVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
UsersWithBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
CombinedResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        UV.UpVotes,
        UV.DownVotes,
        UB.BadgeCount
    FROM 
        RankedPosts RP
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN 
        PostVotes UV ON RP.PostId = UV.PostId
    LEFT JOIN 
        UsersWithBadges UB ON U.Id = UB.UserId
)
SELECT 
    CR.PostId,
    CR.Title,
    CR.Score,
    CR.CreationDate,
    CR.OwnerDisplayName,
    COALESCE(CR.UpVotes, 0) AS UpVotes,
    COALESCE(CR.DownVotes, 0) AS DownVotes,
    COALESCE(CR.BadgeCount, 0) AS BadgeCount
FROM 
    CombinedResults CR
WHERE 
    CR.Rank = 1
ORDER BY 
    CR.Score DESC, CR.CreationDate DESC;
