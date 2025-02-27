WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS rn,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON c.PostId = rp.PostId
),
FilteredPosts AS (
    SELECT 
        ps.*, 
        RANK() OVER (ORDER BY Score DESC) AS RankScore
    FROM 
        PostStats ps
    WHERE 
        ps.BadgeCount > 0
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Tags,
    fp.Score,
    fp.ViewCount,
    fp.BadgeCount,
    fp.CommentCount,
    CASE 
        WHEN fp.Score > 100 THEN 'Highly Active'
        WHEN fp.Score IS NULL THEN 'No Score'
        ELSE 'Moderate Activity'
    END AS ActivityLevel
FROM 
    FilteredPosts fp
WHERE 
    fp.RankScore <= 10
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
