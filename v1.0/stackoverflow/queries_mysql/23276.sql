
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        AVG(COALESCE(v.VoteTypeId, 0)) AS AverageVoteType,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT TRIM(BOTH ' ' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) tags_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tags_array.TagName
    WHERE 
        pt.Name IN ('Question', 'Answer')
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Rank,
        rp.CommentCount,
        CASE 
            WHEN rp.AverageVoteType = 0 THEN 'No Votes'
            WHEN rp.AverageVoteType IS NULL THEN 'No Votes Recorded'
            ELSE CONCAT('Average Vote Type: ', CAST(rp.AverageVoteType AS CHAR))
        END AS VoteDescription,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    u.DisplayName AS OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.VoteDescription,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
ORDER BY 
    fp.CommentCount DESC, fp.CreationDate DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM FilteredPosts) / 2;
