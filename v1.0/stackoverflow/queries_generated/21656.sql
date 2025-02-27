WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC, P.CreationDate ASC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Filter for questions
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
RecentActivity AS (
    SELECT 
        P.Id,
        P.Title,
        COALESCE(MAX(CA.CreationDate), P.CreationDate) AS MostRecentActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments CA ON P.Id = CA.PostId
    GROUP BY 
        P.Id, P.Title
),

-- Retrieving old history details for closed posts
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS HistoryDate,
        PH.Comment AS CloseReason,
        PH.UserDisplayName AS ClosedBy
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
),

-- Final selection with outer joins and additional analysis
FinalPostReport AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        PVS.TotalUpvotes,
        PVS.TotalDownvotes,
        RA.MostRecentActivity,
        COALESCE(CPH.CloseReason, 'Not Closed') AS CloseReason,
        COALESCE(CPH.ClosedBy, 'N/A') AS ClosedBy,
        CASE 
            WHEN RP.Score > 0 THEN 'Popular'
            WHEN RP.Score = 0 THEN 'Neutral'
            WHEN RP.Score < 0 THEN 'Unpopular'
        END AS PopularityStatus
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostVoteSummary PVS ON RP.PostId = PVS.PostId
    LEFT JOIN 
        RecentActivity RA ON RP.PostId = RA.Id
    LEFT JOIN 
        ClosedPostHistory CPH ON RP.PostId = CPH.PostId
    WHERE 
        RP.PostRank <= 3 -- Limit to top 3 posts per user
)

-- Final selection along with a set operator for demonstration purposes
SELECT * FROM FinalPostReport
UNION ALL
SELECT 
    NULL AS PostId, 
    'Summary Stats' AS Title, 
    NULL AS CreationDate, 
    NULL AS Score, 
    NULL AS ViewCount, 
    NULL AS OwnerDisplayName, 
    COUNT(PostId) AS TotalPosts, 
    SUM(TotalUpvotes) AS TotalVotes, 
    SUM(TotalDownvotes) AS TotalDownVotes, 
    NULL AS MostRecentActivity, 
    NULL AS CloseReason, 
    NULL AS ClosedBy, 
    NULL AS PopularityStatus
FROM 
    FinalPostReport;
