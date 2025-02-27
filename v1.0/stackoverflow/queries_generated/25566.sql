WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) AS RankInLocation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Looking specifically at Questions
        AND u.Location IS NOT NULL
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.CreationDate,
        rp.Owner,
        t.TagName
    FROM 
        RankedPosts rp
    CROSS JOIN 
        (SELECT DISTINCT UNNEST(string_to_array(rp.Tags, '><')) AS TagName FROM RankedPosts) t 
    WHERE 
        rp.RankInLocation <= 5 -- Top 5 questions per location
),
BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    WHERE 
        b.Date > CURRENT_DATE - INTERVAL '1 year' -- Considering badges earned in the last year
    GROUP BY 
        u.Id
)
SELECT 
    tp.Owner,
    tp.Title,
    tp.Tags,
    tp.Score,
    tp.CreationDate,
    bc.TotalBadges,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    TaggedPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    BadgeCounts bc ON tp.Owner = (SELECT DisplayName FROM Users WHERE Id = bc.UserId)
GROUP BY 
    tp.Owner, tp.Title, tp.Tags, tp.Score, tp.CreationDate, bc.TotalBadges
ORDER BY 
    tp.Score DESC, bc.TotalBadges DESC
LIMIT 10;
