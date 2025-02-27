WITH RecursivePostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostData r ON p.ParentId = r.PostId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 END) AS CloseReopenCount,
        COUNT(*) AS TotalEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.PostId,
    rp.CreationDate,
    pv.UpVotes,
    pv.DownVotes,
    pv.TotalVotes,
    ph.CloseReopenCount,
    ph.TotalEdits,
    ua.TotalPosts,
    ua.TotalScore,
    ua.TotalBadges,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    (SELECT COUNT(*)
     FROM Comments c
     WHERE c.PostId = rp.PostId) AS CommentCount
FROM 
    RecursivePostData rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
LEFT JOIN 
    UserAggregates ua ON rp.OwnerUserId = ua.UserId
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
