
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
),

RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE
        v.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        v.PostId
),

ClosedPosts AS (
    SELECT 
        h.PostId,
        h.CreationDate AS ClosedDate,
        h.UserId AS CloserUserId,
        h.Comment
    FROM 
        PostHistory h
    WHERE 
        h.PostHistoryTypeId = 10
)

SELECT 
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    up.ViewCount,
    up.AnswerCount,
    rv.UpVotes,
    rv.DownVotes,
    cp.ClosedDate,
    cp.CloserUserId
FROM 
    RankedPosts up
LEFT JOIN 
    RecentVotes rv ON up.PostId = rv.PostId
LEFT JOIN 
    ClosedPosts cp ON up.PostId = cp.PostId
WHERE 
    up.Rank = 1
    AND (cp.ClosedDate IS NULL OR cp.ClosedDate >= NOW() - INTERVAL 60 DAY)
ORDER BY 
    up.Score DESC, up.CreationDate DESC
LIMIT 100;
