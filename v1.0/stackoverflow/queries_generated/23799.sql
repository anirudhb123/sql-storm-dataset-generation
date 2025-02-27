WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS ScoreRank,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(P.Tags, '><')) AS TagName) T ON TRUE
    GROUP BY 
        U.Id
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= NOW() - INTERVAL '30 days' 
    GROUP BY 
        V.UserId
),
PostHistoryWithClosed AS (
    SELECT 
        PH.PostId,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseOpenCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeletionCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
TopUsersWithTags AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.TotalScore,
        UA.ScoreRank,
        UA.TagsUsed,
        RV.VoteCount,
        RV.UpVoteCount,
        RV.DownVoteCount,
        PHWC.CloseOpenCount,
        PHWC.DeletionCount
    FROM 
        UserActivity UA
    LEFT JOIN 
        RecentVotes RV ON UA.UserId = RV.UserId
    LEFT JOIN 
        PostHistoryWithClosed PHWC ON UA.PostCount > 0
    WHERE 
        UA.Reputation > (
            SELECT AVG(Reputation) FROM Users
        )
    ORDER BY 
        UA.ScoreRank
    LIMIT 10
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.TotalScore,
    T.VoteCount,
    T.UpVoteCount,
    T.DownVoteCount,
    COALESCE(T.CloseOpenCount, 0) AS OpenClosedCount,
    COALESCE(T.DeletionCount, 0) AS PostDeletionCount,
    CASE 
        WHEN T.TagsUsed IS NULL THEN 'No Tags Used' 
        ELSE T.TagsUsed 
    END AS TagsOverview
FROM 
    TopUsersWithTags T
WHERE 
    (T.TagsUsed IS NOT NULL OR T.TagsUsed IS NULL) -- This bizarre condition will always yield true
    AND T.CloseOpenCount = 0 -- Only include posts never closed
ORDER BY 
    T.Reputation DESC;
