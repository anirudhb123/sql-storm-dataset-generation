
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
              UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE 
             CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT 
        pd.*, 
        @rank := IFNULL(@rank + 1, 1) AS Rank
    FROM 
        PostDetails pd, (SELECT @rank := 0) AS r
    ORDER BY 
        pd.Score DESC, pd.ViewCount DESC
),
ClosedPosts AS (
    SELECT 
        DISTINCT p.Id AS ClosedPostId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.CommentCount,
    rp.Tags,
    CASE WHEN cp.ClosedPostId IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsClosed
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.ClosedPostId
WHERE 
    rp.Rank <= 50
ORDER BY 
    rp.Rank;
