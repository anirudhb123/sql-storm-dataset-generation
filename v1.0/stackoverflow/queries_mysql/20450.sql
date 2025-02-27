
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankByScoreViewCount,
        COALESCE(uh.UpVotes, 0) - COALESCE(uh.DownVotes, 0) AS NetVotes,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            UserId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            UserId) uh ON u.Id = uh.UserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            GROUP_CONCAT(TagName ORDER BY TagName ASC SEPARATOR ', ') AS TagName 
         FROM 
            (SELECT 
               p.Id AS PostId, 
               TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName 
             FROM Posts p 
             JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                   SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                   SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t
         GROUP BY PostId) t ON p.Id = t.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(*) AS HistoryChangeCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)
    GROUP BY 
        ph.PostId
),
PostsWithHistory AS (
    SELECT 
        rp.*,
        phd.LastClosedDate,
        phd.LastReopenedDate,
        phd.HistoryChangeCount,
        CASE 
            WHEN phd.HistoryChangeCount > 0 THEN 'Contains History Changes'
            ELSE 'No History Changes'
        END AS HistoryChangeStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails phd ON rp.Id = phd.PostId
)
SELECT 
    pwh.Title,
    pwh.CreationDate,
    pwh.ViewCount,
    pwh.Score,
    pwh.RankByScoreViewCount,
    pwh.NetVotes,
    pwh.Tags,
    pwh.LastClosedDate,
    pwh.LastReopenedDate,
    pwh.HistoryChangeCount,
    pwh.HistoryChangeStatus
FROM 
    PostsWithHistory pwh
WHERE 
    (pwh.LastClosedDate IS NULL OR pwh.LastReopenedDate IS NOT NULL) 
    AND pwh.ViewCount > 100
ORDER BY 
    pwh.RankByScoreViewCount ASC, pwh.CreationDate DESC;
