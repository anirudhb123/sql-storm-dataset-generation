WITH RecursiveTagCount AS (
    SELECT 
        Posts.Id AS PostId,
        array_length(string_to_array(Posts.Tags, '>'), 1) AS TagCount,
        Posts.CreationDate
    FROM 
        Posts
    WHERE 
        Posts.PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        pf.PostId,
        pf.TagCount,
        pf.CreationDate
    FROM 
        Posts pf
        INNER JOIN RecursiveTagCount rtc ON pf.Id = rtc.PostId
    WHERE 
        pf.CreationDate < rtc.CreationDate
),
RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 -- Filter users with reputations above 1000
),
TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        COUNT(DISTINCT Posts.OwnerUserId) AS UserCount
    FROM 
        Tags
        LEFT JOIN Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY 
        Tags.TagName
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MIN(PH.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        PH.PostId
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    COALESCE(TS.PostCount, 0) AS TaggedPosts,
    COALESCE(TS.UserCount, 0) AS UniqueUsers,
    COALESCE(PVS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PVS.DownVotes, 0) AS TotalDownVotes,
    COALESCE(CPH.CloseCount, 0) AS TotalCloseEvents,
    COALESCE(CPH.FirstClosedDate, 'No closures') AS FirstClosureDate
FROM 
    RankedUsers TU
LEFT JOIN 
    TagStatistics TS ON TU.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Tags IS NOT NULL)
LEFT JOIN 
    PostVoteSummary PVS ON TU.UserId IN (SELECT OwnerUserId FROM Posts)
LEFT JOIN 
    ClosedPostHistory CPH ON TU.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id IN (SELECT PostId FROM CPH))
WHERE 
    TU.UserRank <= 10 -- Only top 10 users by reputation
ORDER BY 
    TU.Reputation DESC;
