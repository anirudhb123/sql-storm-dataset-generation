
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            p.Id, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) numbers INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) 
             -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n-1) AS t ON TRUE
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Score
), 
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), 
PostHistoryFlags AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS IsDeleted
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ps.UpVotes,
    ps.DownVotes,
    ph.IsClosed,
    ph.IsReopened,
    ph.IsDeleted,
    rp.CommentCount,
    rp.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary ps ON rp.PostId = ps.PostId
LEFT JOIN 
    PostHistoryFlags ph ON rp.PostId = ph.PostId
WHERE 
    rp.ScoreRank <= 5 AND
    (ph.IsClosed IS NULL OR ph.IsClosed = 0)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
