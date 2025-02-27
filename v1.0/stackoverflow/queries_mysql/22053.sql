
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > (CAST('2024-10-01' AS DATE) - INTERVAL 1 YEAR)
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVoteCount,
        rp.DownVoteCount,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = rp.PostId) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId AND b.Class = 1 
    WHERE 
        rp.RankScore <= 10
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
    WHERE 
        ph.CreationDate > (CAST('2024-10-01' AS DATE) - INTERVAL 30 DAY)
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.ViewCount,
    tq.Score,
    tq.UpVoteCount,
    tq.DownVoteCount,
    tq.BadgeName,
    tq.CommentCount,
    ra.UserId,
    ra.CreationDate AS RecentActivityDate,
    ra.Comment AS RecentActivityComment,
    ra.HistoryType
FROM 
    TopQuestions tq
LEFT JOIN 
    RecentActivity ra ON ra.PostId = tq.PostId
ORDER BY 
    tq.Score DESC,
    tq.ViewCount DESC,
    ra.CreationDate DESC;
