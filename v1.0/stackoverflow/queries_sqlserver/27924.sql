
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS Tag
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
MostVotedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title
    ORDER BY 
        VoteCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
),
TopCommentedPosts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
    HAVING 
        COUNT(c.Id) > 10 
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
)

SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    tc.PostCount AS TagPostCount,
    mvp.VoteCount,
    tcp.CommentCount,
    rph.CreationDate AS RecentChangeDate,
    CASE 
        WHEN rph.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN rph.PostHistoryTypeId = 11 THEN 'Reopened'
        ELSE 'No Recent Change'
    END AS RecentChangeType
FROM 
    Posts p
LEFT JOIN 
    TagCounts tc ON p.Tags LIKE '%' + '<' + tc.TagName + '>%'
LEFT JOIN 
    MostVotedPosts mvp ON p.Id = mvp.Id
LEFT JOIN 
    TopCommentedPosts tcp ON p.Id = tcp.PostId
LEFT JOIN 
    RecentPostHistory rph ON p.Id = rph.PostId AND rph.rn = 1
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC;
