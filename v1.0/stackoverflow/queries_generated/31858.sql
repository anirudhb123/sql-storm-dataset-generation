WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        1 AS Level,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.Score,
        p2.CreationDate,
        p2.ViewCount,
        p2.AcceptedAnswerId,
        Level + 1,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p2.Id), 0) AS CommentCount
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostStats r ON r.PostId = p2.ParentId
), 
PostHistoryStats AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(pt.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH ' ' FROM tag)
    GROUP BY 
        p.Id, p.Title
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.CreationDate,
    r.ViewCount,
    r.CommentCount,
    COALESCE(ph.HistoryCount, 0) AS PostHistoryCount,
    ph.LastEditDate,
    tp.Tags,
    u.UserId,
    u.DisplayName AS OwnerName,
    u.PostCount AS UserPostCount,
    u.TotalScore AS UserTotalScore,
    u.Rank AS UserRank
FROM 
    RecursivePostStats r
LEFT JOIN 
    PostHistoryStats ph ON r.PostId = ph.PostId
LEFT JOIN 
    TaggedPosts tp ON r.PostId = tp.PostId
LEFT JOIN 
    Users u ON r.AccpetedAnswerId = u.Id
WHERE 
    r.ViewCount > 100 AND
    r.CreationDate < NOW() - INTERVAL '30 days'
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
