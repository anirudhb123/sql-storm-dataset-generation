WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        u.DisplayName AS AuthorName,
        rp.Tags,
        rp.Score
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        TopPosts
    GROUP BY 
        TagName
),
BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.AuthorName,
    ts.TagName,
    ts.PostCount,
    bc.BadgeCount
FROM 
    TopPosts tp
JOIN 
    TagStatistics ts ON ts.TagName = ANY(string_to_array(tp.Tags, ','))
JOIN 
    BadgeCounts bc ON tp.OwnerUserId = bc.UserId
ORDER BY 
    tp.Score DESC, ts.PostCount DESC;
