WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName,
        P.PostTypeId,
        COALESCE(AR.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts AR ON P.Id = AR.AcceptedAnswerId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.DisplayName, AR.AcceptedAnswerId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.LastAccessDate > CURRENT_DATE - INTERVAL '60 days'
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
),
ExceptionalCase AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
    HAVING 
        HistoryCount > 5 AND
        PH.PostHistoryTypeId IN (10, 12) -- Mainly looking for Closed or Deleted posts
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CreationDate,
    RP.DisplayName,
    RP.PostTypeId,
    RP.AcceptedAnswerId,
    RP.UpVotes,
    RP.DownVotes,
    AU.UserRank,
    PT.TagName,
    CASE 
        WHEN EC.PostId IS NOT NULL THEN 'Caution: Post Closed or Deleted'
        ELSE 'Active Post'
    END AS PostStatus,
    CASE
        WHEN RP.ViewCount IS NULL THEN 'No Views Yet'
        WHEN RP.ViewCount < 100 THEN 'Low Visibility'
        WHEN RP.ViewCount BETWEEN 100 AND 500 THEN 'Moderate Visibility'
        ELSE 'High Visibility'
    END AS VisibilityStatus
FROM 
    RecentPosts RP
LEFT JOIN 
    ActiveUsers AU ON RP.OwnerUserId = AU.UserId
LEFT JOIN 
    PopularTags PT ON RP.Tags LIKE '%' || PT.TagName || '%'
LEFT JOIN 
    ExceptionalCase EC ON RP.PostId = EC.PostId
WHERE 
    (RP.UpVotes - RP.DownVotes) >= 0 
ORDER BY 
    RP.ViewCount DESC,
    AU.UserRank ASC NULLS LAST
LIMIT 100;
