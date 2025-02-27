
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate
),
RecentPostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ',') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
         FROM Posts p
         JOIN (SELECT a.N FROM (SELECT 1 AS N UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                                  UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) 
               AS a) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY 
        p.Id
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    rp.Id,
    rp.Title,
    rp.CommentCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    plt.Tags,
    CASE 
        WHEN rp.CommentCount > 50 THEN 'Hot Post'
        WHEN rp.CommentCount = 0 AND pv.UpVotes > pv.DownVotes THEN 'Potentially Viral'
        ELSE 'Normal Activity'
    END AS ActivityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.Id = pv.PostId
LEFT JOIN 
    RecentPostTags plt ON rp.Id = plt.PostId
WHERE 
    (rp.PostTypeId = 1 AND rp.rn <= 5) OR (rp.PostTypeId = 2 AND rp.CommentCount > 10)
ORDER BY 
    rp.CreationDate DESC, rp.CommentCount DESC
LIMIT 100;
