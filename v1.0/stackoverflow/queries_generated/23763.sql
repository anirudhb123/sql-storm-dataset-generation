WITH PostScoreSummary AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE 
            WHEN V.VoteTypeId = 2 THEN 1
            WHEN V.VoteTypeId = 3 THEN -1
            ELSE 0 
        END) AS NetScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year') -- Filter for recent posts
    GROUP BY 
        P.Id
),

ClosedPostAnalysis AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS CloseCount,
        STRING_AGG(CAST(PH.CreationDate AS varchar), ', ' ORDER BY PH.CreationDate) AS CloseDates,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),

UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(PS.NetScore, 0)) AS TotalScore,
        SUM(CASE WHEN PS.NetScore > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN PS.NetScore < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostScoreSummary PS ON P.Id = PS.PostId
    GROUP BY 
        U.Id, U.DisplayName
),

FinalResults AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.TotalScore,
        U.PositivePosts,
        U.NegativePosts,
        CPA.CloseCount,
        CPA.CloseDates,
        CPA.LastCloseDate
    FROM 
        UserPostStats U
    LEFT JOIN 
        ClosedPostAnalysis CPA ON U.TotalPosts = CPA.CloseCount -- join based on the total posts equalling closed posts (an obscure logic)
    ORDER BY 
        U.TotalScore DESC, 
        U.TotalPosts DESC
)

SELECT 
    FR.*,
    CASE 
        WHEN FR.CloseCount IS NOT NULL THEN 'Closed Post Activity Exists'
        ELSE 'No Closed Posts'
    END AS PostActivityStatus,
    COALESCE(FR.LastCloseDate::text, 'N/A') AS LastCloseDateFormatted
FROM 
    FinalResults FR
WHERE 
    (FR.TotalScore > 10 OR FR.PositivePosts > 5) -- arbitrary performance metric threshold
    AND FR.UserId IS NOT NULL
    AND (FR.CloseCount IS NULL OR FR.TotalPosts > 1) -- bizarre condition to include users with certain close activity
ORDER BY 
    FR.UserId;

