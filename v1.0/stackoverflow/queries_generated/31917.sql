WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Consider only Questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Created in the last year
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10) -- Edit Title, Edit Body, Edit Tags, Closed
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
ActiveUserPostHistory AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT ph.PostId) AS EditedPosts,
        AVG(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.HistoryCount ELSE NULL END) AS AvgTitleEdits,
        AVG(CASE WHEN ph.PostHistoryTypeId = 5 THEN ph.HistoryCount ELSE NULL END) AS AvgBodyEdits,
        AVG(CASE WHEN ph.PostHistoryTypeId = 6 THEN ph.HistoryCount ELSE NULL END) AS AvgTagEdits
    FROM 
        UserActivity u
    LEFT JOIN 
        PostHistoryInfo ph ON u.UserId = ph.PostId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ra.PostId,
    ra.Title,
    ua.DisplayName AS OwnerDisplayName,
    ua.TotalQuestions,
    ua.TotalBounty,
    ActiveUser.EditedPosts,
    ActiveUser.AvgTitleEdits,
    ActiveUser.AvgBodyEdits,
    ActiveUser.AvgTagEdits
FROM 
    RankedPosts ra
JOIN 
    UserActivity ua ON ra.OwnerUserId = ua.UserId
LEFT JOIN 
    ActiveUserPostHistory ActiveUser ON ua.DisplayName = ActiveUser.DisplayName
WHERE 
    ra.PostRank = 1 -- Only most recent question per user
ORDER BY 
    ra.CreationDate DESC;

