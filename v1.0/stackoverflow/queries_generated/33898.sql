WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(PH.Comment, 'No comments available') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts AS P
    LEFT JOIN 
        Users AS U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory AS PH ON P.Id = PH.PostId 
        AND PH.PostHistoryTypeId IN (4, 5, 24)  -- Edit Title, Edit Body, Suggested Edit
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
AggregateVoteStats AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (1, 6) THEN 1 END) AS AcceptedVotes  -- Accepted by Originator or Close vote
    FROM 
        Posts AS P
    LEFT JOIN 
        Votes AS V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges AS B
    WHERE 
        B.Class = 1  -- Only Gold badges
    GROUP BY 
        B.UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    RP.OwnerDisplayName,
    AG.UpVotes,
    AG.DownVotes,
    AG.AcceptedVotes,
    CASE 
        WHEN UB.BadgeCount > 0 THEN UB.BadgeNames 
        ELSE 'No Gold Badges' 
    END AS GoldBadges,
    RP.LastEditComment
FROM 
    RecentPosts AS RP
JOIN 
    AggregateVoteStats AS AG ON RP.PostId = AG.PostId
LEFT JOIN 
    UserBadges AS UB ON RP.OwnerDisplayName = (
        SELECT DisplayName 
        FROM Users 
        WHERE Id = UB.UserId
    )
WHERE 
    RP.PostRank = 1  -- Only the latest post for each user
ORDER BY 
    RP.CreationDate DESC;
