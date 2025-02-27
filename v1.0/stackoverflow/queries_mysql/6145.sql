
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        BadgeCount,
        UpVotes,
        DownVotes,
        @row_number := @row_number + 1 AS Rank
    FROM 
        PostMetrics, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    *,
    CASE 
        WHEN BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;
