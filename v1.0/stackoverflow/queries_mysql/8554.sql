
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
BestPosts AS (
    SELECT 
        PostID,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        Tags,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    bp.PostID,
    bp.Title,
    bp.CreationDate,
    bp.Score,
    bp.ViewCount,
    bp.OwnerDisplayName,
    bp.Tags,
    bh.Name AS PostHistoryType,
    COUNT(bh.Id) AS HistoryChangeCount
FROM 
    BestPosts bp
LEFT JOIN 
    PostHistory ph ON bp.PostID = ph.PostId 
LEFT JOIN 
    PostHistoryTypes bh ON ph.PostHistoryTypeId = bh.Id
GROUP BY 
    bp.PostID, bp.Title, bp.CreationDate, bp.Score, bp.ViewCount, bp.OwnerDisplayName, bp.Tags, bh.Name
ORDER BY 
    bp.Score DESC, HistoryChangeCount DESC;
