
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @rank := IF(@prevPostTypeId = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prevPostTypeId := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rank := 0, @prevPostTypeId := NULL) r
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.PostTypeId
), RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    WHERE 
        b.Date >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 6 MONTH
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rb.TotalBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = rb.UserId)
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.UpVotes DESC, rp.CommentCount DESC;
