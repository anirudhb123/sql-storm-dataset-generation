WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
),
PostLinksSummary AS (
    SELECT 
        PL.PostId, 
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks PL
    GROUP BY 
        PL.PostId
),
UserBadgeCounts AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Class = 1 OR B.Class = 2  -- Only Gold or Silver badges
    GROUP BY 
        B.UserId
)
SELECT 
    RP.PostId, 
    RP.Title, 
    RP.CreationDate, 
    RP.OwnerDisplayName, 
    RP.UpVoteCount, 
    RP.DownVoteCount,
    COALESCE(PL.RelatedPostCount, 0) AS RelatedPostCount,
    COALESCE(UBC.BadgeCount, 0) AS UserBadgeCount
FROM 
    RankedPosts RP
LEFT JOIN 
    PostLinksSummary PL ON RP.PostId = PL.PostId
LEFT JOIN 
    UserBadgeCounts UBC ON RP.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = UBC.UserId)
WHERE 
    RP.UserPostRank <= 5  -- Top 5 posts per user
ORDER BY 
    RP.CreationDate DESC, 
    UpVoteCount DESC;
