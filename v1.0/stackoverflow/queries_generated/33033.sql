WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000   -- Filtering users with reputation greater than 1000
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(C.Comment) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,       -- Assuming 2 is for UpMod
        SUM(V.VoteTypeId = 3) AS DownVotes      -- Assuming 3 is for DownMod
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'   -- Considering posts in the last 30 days
    GROUP BY 
        P.Id
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10   -- Filtering close events
    GROUP BY 
        PH.PostId
),
FinalMetrics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.CommentCount,
        RP.UpVotes,
        RP.DownVotes,
        COALESCE(CPH.CloseCount, 0) AS CloseCount,
        RU.DisplayName AS TopUser
    FROM 
        RecentPosts RP
    LEFT JOIN 
        ClosedPostHistory CPH ON RP.PostId = CPH.PostId
    LEFT JOIN 
        RankedUsers RU ON RP.OwnerUserId = RU.UserId
    WHERE 
        RP.ViewCount > 100  -- Selecting only posts with a significant view count
)
SELECT 
    FM.PostId,
    FM.Title,
    FM.ViewCount,
    FM.CommentCount,
    FM.UpVotes,
    FM.DownVotes,
    FM.CloseCount,
    FM.TopUser
FROM 
    FinalMetrics FM
WHERE 
    FM.CloseCount < 2  -- Exclude posts with more than one close event
ORDER BY 
    FM.ViewCount DESC
LIMIT 10;  -- Limiting to the top 10 popular posts
