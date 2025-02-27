WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        Posts p2 ON p2.ParentId = p.Id
    LEFT JOIN 
        Tags t ON t.Id IN (
            SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'))
        )
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        CommentCount,
        Tags,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    t.PostId,
    t.Title,
    t.ViewCount,
    t.Score,
    t.CommentCount,
    t.Tags,
    STY.Name AS PostType,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM PostHistory ph
            WHERE ph.PostId = t.PostId 
              AND ph.PostHistoryTypeId IN (10, 11)
        ) THEN 'Closed/Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    TopPosts t
JOIN 
    PostTypes PT ON PT.Id = (SELECT PostTypeId FROM Posts WHERE Id = t.PostId)
JOIN 
    PostHistoryTypes STY ON STY.Id = (SELECT PostHistoryTypeId FROM PostHistory WHERE PostId = t.PostId ORDER BY CreationDate DESC LIMIT 1)
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;
