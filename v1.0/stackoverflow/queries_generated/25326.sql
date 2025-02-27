WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY U.Views DESC) AS ViewsRank
    FROM 
        Users U
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '>')) AS T(TagName) ON P.PostTypeId = 1
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
    ORDER BY 
        P.Score DESC
    LIMIT 10
),
PostVoting AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Class = 1 OR B.Class = 2 -- Gold or Silver Badges
    GROUP BY 
        B.UserId
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.Views,
    T.Title AS TopPostTitle,
    T.Score AS PostScore,
    T.ViewCount AS PostViewCount,
    T.Tags AS PostTags,
    PV.Upvotes,
    PV.Downvotes,
    PV.CloseVotes,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount
FROM 
    RankedUsers RU
JOIN 
    TopPosts T ON RU.UserId = T.OwnerUserId
LEFT JOIN 
    PostVoting PV ON T.PostId = PV.PostId
LEFT JOIN 
    UserBadgeCounts UB ON RU.UserId = UB.UserId
WHERE 
    RU.ReputationRank <= 10
ORDER BY 
    RU.Reputation DESC, T.Score DESC;
