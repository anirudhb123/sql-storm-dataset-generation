
WITH PostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryEditCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        HistoryEditCount,
        UpVotes,
        DownVotes,
        @row_number := @row_number + 1 AS Rank
    FROM 
        PostData, (SELECT @row_number := 0) AS r
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    ViewCount,
    Score,
    OwnerDisplayName,
    CommentCount,
    HistoryEditCount,
    UpVotes,
    DownVotes,
    Rank
FROM 
    RankedPosts
WHERE 
    Rank <= 100
ORDER BY 
    Rank;
