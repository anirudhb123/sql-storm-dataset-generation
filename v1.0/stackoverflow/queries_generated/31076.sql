WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        Score,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id 
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS BountyTotal,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryCount AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ph.HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistoryCount ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, ph.HistoryCount
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    COALESCE(ts.PostCount, 0) AS TagCount,
    COALESCE(ts.TotalScore, 0) AS TagTotalScore,
    u.DisplayName AS Owner,
    u.Reputation AS OwnerReputation,
    u.BountyTotal AS OwnerBountyTotal
FROM 
    RecentPosts rp
LEFT JOIN 
    TagStats ts ON ts.PostCount > 0
LEFT JOIN 
    Users u ON u.Id = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = rp.Id
    )
WHERE 
    rp.Score > 10
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;

