WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS EngagementRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpVotes,
        DownVotes
    FROM 
        UserEngagement
    WHERE 
        EngagementRank <= 10
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.PostTypeId,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    COALESCE(RP.PostId, -1) AS RecentPostId,
    COALESCE(RP.Title, 'No recent posts') AS RecentPostTitle,
    COALESCE(RP.CreationDate, '1900-01-01') AS PostCreationDate,
    CASE 
        WHEN TU.UpVotes > TU.DownVotes THEN 'Positively Engaged'
        WHEN TU.UpVotes < TU.DownVotes THEN 'Negatively Engaged'
        ELSE 'Neutral Engagement'
    END AS EngagementProfile,
    STRING_AGG(DISTINCT PT.Name, ', ') AS PostTypeNames
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPosts RP ON TU.UserId = RP.OwnerUserId AND RP.RecentRank = 1
LEFT JOIN 
    PostTypes PT ON RP.PostTypeId = PT.Id
GROUP BY 
    TU.UserId, TU.DisplayName, TU.Reputation, RP.PostId, RP.Title, RP.CreationDate, TU.UpVotes, TU.DownVotes
ORDER BY 
    TU.Reputation DESC;

-- Considerations:
-- 1. The query evaluates engagement rankings and highlights potentially overlooked users.
-- 2. It gathers engagement stats while also focusing on recent activity over the past month.
-- 3. The use of COALESCE handles potential NULL values gracefully, ensuring meaningful output.
-- 4. It integrates STRING_AGG to provide a concatenated string of post types to present a comprehensive view.
