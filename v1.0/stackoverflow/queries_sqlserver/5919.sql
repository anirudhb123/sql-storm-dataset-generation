
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
        LEFT JOIN Comments c ON c.PostId = p.Id
        LEFT JOIN Votes v ON v.PostId = p.Id
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
        LEFT JOIN (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '<>')) AS t ON 1 = 1
    WHERE 
        p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, p.OwnerUserId, 
        u.DisplayName, pt.Name
),
RankedPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    CommentCount,
    UpVotes,
    DownVotes,
    CreationDate,
    LastActivityDate,
    OwnerUserId,
    OwnerDisplayName,
    PostType,
    Tags
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;
