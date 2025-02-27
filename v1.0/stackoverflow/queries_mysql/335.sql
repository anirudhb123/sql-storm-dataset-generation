
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.PostTypeId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        (@rank := IF(@currentPostType = ps.PostTypeId, @rank + 1, 1)) AS Rank,
        @currentPostType := ps.PostTypeId
    FROM 
        PostStats ps, (SELECT @rank := 0, @currentPostType := NULL) r
    ORDER BY 
        ps.PostTypeId, ps.UpVoteCount DESC 
)
SELECT 
    r.PostId,
    r.Title,
    r.PostTypeId,
    r.CommentCount,
    r.UpVoteCount,
    r.DownVoteCount,
    CASE 
        WHEN r.Rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS RankCategory,
    (SELECT GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ',') 
     FROM Tags t 
     JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
           FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
                 SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
           WHERE numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) + 1) 
           ) AS tag ON t.TagName = tag.TagName
     WHERE p.Id = r.PostId) AS Tags
FROM 
    RankedPosts r
LEFT JOIN 
    Posts p ON r.PostId = p.Id
WHERE 
    r.Rank <= 10 OR r.PostTypeId IN (1, 2)  
ORDER BY 
    r.UpVoteCount DESC;
