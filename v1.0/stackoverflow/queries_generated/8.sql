WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND P.Score > 0
),
PostVoteDetails AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Votes V
    JOIN 
        PostHistory PH ON V.PostId = PH.PostId
    WHERE 
        V.CreationDate > (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        V.PostId
),
RecentUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate > (CURRENT_DATE - INTERVAL '2 years')
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.AnswerCount,
    COALESCE(PVD.Upvotes, 0) AS TotalUpvotes,
    COALESCE(PVD.Downvotes, 0) AS TotalDownvotes,
    COALESCE(PVD.CloseVotes, 0) AS TotalCloseVotes,
    RU.UserId,
    RU.DisplayName AS UserDisplayName,
    RU.Reputation,
    RU.BadgeCount,
    CASE 
        WHEN RP.OwnerRank = 1 THEN 'Latest Post' 
        ELSE 'Earlier Post' 
    END AS PostStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVoteDetails PVD ON RP.PostId = PVD.PostId
JOIN 
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN 
    RecentUsers RU ON U.Id = RU.UserId
WHERE 
    (PVD.CloseVotes IS NULL OR PVD.CloseVotes < 3)
ORDER BY 
    RP.CreationDate DESC, RP.Score DESC
LIMIT 100;
