WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
)

SELECT 
    u.Id AS UserId, 
    u.DisplayName, 
    COUNT(DISTINCT rp.Id) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.ViewCount) AS AvgViewCount,
    SUM(rp.UpVoteCount) AS TotalUpVotes,
    SUM(rp.DownVoteCount) AS TotalDownVotes,
    CASE 
        WHEN SUM(rp.Score) > 100 THEN 'High Performer'
        WHEN SUM(rp.Score) BETWEEN 50 AND 100 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT rp.Id) > 10 
ORDER BY 
    TotalScore DESC;

WITH RecentPostHistory AS (
    SELECT 
        ph.UserId,
        p.Title,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '1 month'
    AND 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags Edited
)

SELECT 
    rph.UserId,
    COUNT(*) AS RecentEdits,
    STRING_AGG(rph.Title, ', ') AS EditedPostTitles
FROM 
    RecentPostHistory rph
WHERE 
    rph.RecentEdit = 1  -- Get only the most recent edit
GROUP BY 
    rph.UserId
HAVING 
    COUNT(*) > 5
ORDER BY 
    RecentEdits DESC;
