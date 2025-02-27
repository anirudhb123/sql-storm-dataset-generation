WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        Score,
        ParentId,
        1 AS Level
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r 
    ON 
        p.ParentId = r.Id
), 
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentActivity AS (
    SELECT 
        P.Id,
        P.Title,
        MAX(CASE WHEN C.UserId IS NOT NULL THEN C.CreationDate ELSE NULL END) AS LastCommentDate,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title
),
PostViewSummary AS (
    SELECT 
        OwnerUserId,
        COUNT(DISTINCT Id) AS PostCount,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserBadgeSummary AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    P.Id AS PostId,
    P.Title,
    P.Score,
    COALESCE(PVS.UpVotes, 0) AS UpVotes,
    COALESCE(PVS.DownVotes, 0) AS DownVotes,
    COALESCE(RA.LastCommentDate, 'No comments') AS LastComment,
    COALESCE(RA.CommentCount, 0) AS RecentComments,
    PH.Id AS ParentPostId,
    BS.BadgeCount,
    U.Reputation AS UserReputation
FROM 
    RecursivePostHierarchy PH
LEFT JOIN 
    PostVoteSummary PVS ON PH.Id = PVS.PostId
LEFT JOIN 
    RecentActivity RA ON PH.Id = RA.Id
LEFT JOIN 
    PostViewSummary PVSUM ON PH.Id = PVSUM.OwnerUserId
JOIN 
    Users U ON PH.OwnerUserId = U.Id
LEFT JOIN 
    UserBadgeSummary BS ON BS.Id = U.Id
WHERE 
    (PVS.TotalVotes > 10 OR RA.CommentCount > 5) 
ORDER BY 
    PH.Score DESC, 
    UpVotes DESC
LIMIT 100;
