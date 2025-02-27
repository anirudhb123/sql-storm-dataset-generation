WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only questions
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
BadgesCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostHistoryAggregated AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),
FilteredPostHistory AS (
    SELECT 
        P.Id AS PostId,
        CASE 
            WHEN PH.HistoryCount > 10 THEN 'Highly Edited'
            ELSE 'Less Edited'
        END AS EditStatus
    FROM 
        Posts P
    JOIN 
        PostHistoryAggregated PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  -- Considering title, body, and tags edits only
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.PositiveScorePosts,
    U.NegativeScorePosts,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    T.TagName,
    TA.AverageScore,
    F.EditStatus
FROM 
    UserStats U
JOIN 
    RankedPosts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    BadgesCount B ON U.UserId = B.UserId
LEFT JOIN 
    Tags T ON T.Id IN (SELECT UNNEST(string_to_array(P.Tags, ','))::int)
LEFT JOIN 
    TagStats TA ON T.TagName = TA.TagName
LEFT JOIN 
    FilteredPostHistory F ON P.PostId = F.PostId
WHERE 
    U.Reputation >= 1000  -- Filtering users with reputation of at least 1000
ORDER BY 
    U.Reputation DESC, 
    P.CreationDate DESC;
