WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
    
    UNION ALL
    
    SELECT 
        a.Id,
        a.Title,
        a.PostTypeId,
        a.OwnerUserId,
        a.CreationDate,
        a.Score,
        a.AcceptedAnswerId,
        rp.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE rp ON a.ParentId = rp.Id
    WHERE 
        a.PostTypeId = 2  -- And for answers
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS DeletionDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 1 THEN 1 END) AS TitleUpdates,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 6 THEN 1 END) AS TagUpdates
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserStatistics AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Location,
        COALESCE(SUM(pp.Score), 0) AS TotalScore,
        COALESCE(COUNT(DISTINCT b.Id), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts pp ON pp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    UP.Id AS UserId,
    UP.DisplayName,
    UP.Reputation,
    UP.Location,
    PPS.DeletedPostCount,
    COALESCE(PVS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PVS.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PHS.TitleUpdates, 0) AS TitleUpdatesCount,
    COALESCE(PHS.TagUpdates, 0) AS TagUpdatesCount,
    COALESCE(PVS.TotalVotes, 0) AS TotalVotes,
    ROUND(COALESCE(AVG(PPS.TotalScore), 0), 2) AS AvgScore
FROM 
    UserStatistics UP
LEFT JOIN 
    (SELECT 
         UserId,
         COUNT(DISTINCT ph.PostId) AS DeletedPostCount
     FROM 
         PostHistory ph
     WHERE 
         ph.PostHistoryTypeId = 12 -- Account for deleted posts
     GROUP BY 
         UserId) PPS ON UP.Id = PPS.UserId
LEFT JOIN 
    PostVoteStats PVS ON UP.Id = PVS.PostId
LEFT JOIN 
    PostHistorySummary PHS ON PHS.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = UP.Id)
WHERE 
    UP.Reputation >= 1000
ORDER BY 
    UP.Reputation DESC, UP.DisplayName;
