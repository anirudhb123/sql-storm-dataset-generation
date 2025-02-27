
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        GROUP_CONCAT(t.TagName) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
         FROM 
         (SELECT @row := @row + 1 AS n
          FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) t1,
               (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) t2,
               (SELECT @row := 0) t0) n
         WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))))
        ) AS t ON true
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
FilterPosts AS (
    SELECT 
        *,
        CASE 
            WHEN Upvotes - Downvotes > 0 THEN 'Positive'
            WHEN Upvotes - Downvotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts
    WHERE 
        CommentCount > 5 AND PostRank = 1
)
SELECT 
    f.PostId,
    f.Title,
    u.DisplayName AS OwnerName,
    f.TagsList,
    f.Sentiment
FROM 
    FilterPosts f
JOIN 
    Users u ON f.OwnerUserId = u.Id
WHERE 
    u.Reputation > 500
ORDER BY 
    f.Sentiment DESC, f.Upvotes DESC
LIMIT 10;
