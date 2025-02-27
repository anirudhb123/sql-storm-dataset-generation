
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.CreationDate DESC) AS LocationRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND u.Location IS NOT NULL
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.OwnerDisplayName,
    r.AcceptedAnswerId,
    rt.TagName,
    a.CommentCount,
    a.Upvotes,
    a.Downvotes,
    r.LocationRank
FROM 
    RankedPosts r
JOIN 
    PopularTags rt ON INSTR(r.Body, rt.TagName) > 0
JOIN 
    RecentActivity a ON r.PostId = a.PostId
WHERE 
    r.LocationRank <= 5 
ORDER BY 
    r.LocationRank, a.Upvotes DESC, a.CommentCount DESC;
